# frozen_string_literal: true

module Foxtail
  class Bundle
    # Pattern resolution engine
    # Corresponds to fluent-bundle/src/resolver.ts
    class Resolver
      # Unicode bidi isolation characters
      FSI = "\u2068" # First Strong Isolate
      private_constant :FSI

      PDI = "\u2069" # Pop Directional Isolate
      private_constant :PDI

      def initialize(bundle) = @bundle = bundle

      # Resolve a pattern with the given scope
      def resolve_pattern(pattern, scope)
        case pattern
        when String
          pattern
        when Array
          resolve_complex_pattern(pattern, scope)
        when Parser::AST::StringLiteral, Parser::AST::NumberLiteral, Parser::AST::VariableReference,
             Parser::AST::TermReference, Parser::AST::MessageReference, Parser::AST::FunctionReference,
             Parser::AST::SelectExpression

          # Single expression (shouldn't normally happen in patterns)
          resolve_expression(pattern, scope)
        else
          pattern.to_s
        end
      end

      # Resolve a complex pattern (array of elements)
      def resolve_complex_pattern(elements, scope)
        # Apply bidi isolation only when use_isolating is true and pattern has multiple elements
        use_isolating = @bundle.use_isolating? && elements.size > 1

        elements.map {|element| resolve_pattern_element(element, scope, use_isolating:) }.join
      end

      # Resolve individual pattern elements
      def resolve_pattern_element(element, scope, use_isolating: false)
        case element
        when String
          # Text elements are not wrapped with isolation marks
          element
        when Parser::AST::NumberLiteral
          result = resolve_expression(element, scope)
          # For numeric values in patterns, format for display
          formatted = element.precision > 0 ? format_number(result, element.precision) : result.to_s
          wrap_with_isolation(formatted, use_isolating)
        when Parser::AST::StringLiteral, Parser::AST::VariableReference, Parser::AST::TermReference,
             Parser::AST::MessageReference, Parser::AST::FunctionReference, Parser::AST::SelectExpression

          result = resolve_expression(element, scope)
          wrap_with_isolation(result.to_s, use_isolating)
        else
          wrap_with_isolation(element.to_s, use_isolating)
        end
      end

      # Resolve expressions (variables, terms, messages, functions, etc.)
      def resolve_expression(expr, scope)
        case expr
        when Parser::AST::StringLiteral
          expr.value.to_s
        when Parser::AST::NumberLiteral
          # Return raw numeric value, not formatted string
          expr.value
        when Parser::AST::VariableReference
          resolve_variable_reference(expr, scope)
        when Parser::AST::TermReference
          resolve_term_reference(expr, scope)
        when Parser::AST::MessageReference
          resolve_message_reference(expr, scope)
        when Parser::AST::FunctionReference
          resolve_function_call(expr, scope)
        when Parser::AST::SelectExpression
          resolve_select_expression(expr, scope)
        else
          scope.add_error("Unknown expression type: #{expr.class}")
          "{#{expr.class}}"
        end
      end

      private def format_number(value, precision=nil)
        if precision && precision > 0
          # Format with specified precision
          "%.#{precision}f" % value
        elsif value != Integer(value)
          # Float without precision - keep as is
          value.to_s
        else
          # Integer - format without decimal point
          Integer(value).to_s
        end
      end

      private def wrap_with_isolation(value, use_isolating)
        use_isolating ? "#{FSI}#{value}#{PDI}" : value
      end

      # Resolve variable references
      private def resolve_variable_reference(expr, scope)
        name = expr.name

        value = scope.variable(name)

        if value.nil?
          scope.add_error("Unknown variable: $#{name}")
          "{$#{name}}"
        else
          # Return the raw value, not string representation
          # String conversion should happen at display time
          value
        end
      end

      # Resolve term references
      private def resolve_term_reference(expr, scope)
        name = expr.name
        attr = expr.attr

        # Circular reference check
        unless scope.track(name)
          return "{-#{name}}"
        end

        term = @bundle.term("-#{name}")

        if term.nil?
          scope.add_error("Unknown term: -#{name}")
          scope.release(name)
          return "{-#{name}}"
        end

        # Resolve term value
        result = attr ? resolve_term_attribute(term, attr, scope) : resolve_pattern(term.value, scope)

        scope.release(name)
        result
      end

      # Resolve message references
      private def resolve_message_reference(expr, scope)
        name = expr.name
        attr = expr.attr

        # Circular reference check
        unless scope.track(name)
          return "{#{name}}"
        end

        message = @bundle.message(name)

        if message.nil?
          scope.add_error("Unknown message: #{name}")
          scope.release(name)
          return "{#{name}}"
        end

        # Resolve message value
        result = attr ? resolve_message_attribute(message, attr, scope) : resolve_pattern(message.value, scope)

        scope.release(name)
        result
      end

      # Resolve function calls
      private def resolve_function_call(expr, scope)
        func_name = expr.name
        args = expr.args || []

        func = @bundle.functions[func_name]

        if func.nil?
          scope.add_error("Unknown function: #{func_name}")
          return "{#{func_name}()}"
        end

        # Check if any arguments failed to resolve (contain error markers)
        initial_error_count = scope.errors.length

        # Process arguments: first arg is positional, rest are named args (narg)
        positional_args = []
        options = {}

        args.each do |arg|
          case arg
          when Parser::AST::NamedArgument
            # Named argument - add to options hash
            key = arg.name.to_sym
            value = resolve_expression(arg.value, scope)
            options[key] = value
          else
            # Positional argument
            positional_args << resolve_expression(arg, scope)
          end
        end

        # If arguments resolution generated errors, fail the entire function call
        if scope.errors.length > initial_error_count
          arg_list = args.map {|arg|
            case arg
            when Parser::AST::VariableReference then "$#{arg.name}"
            when Parser::AST::NamedArgument then "#{arg.name}: #{arg.value}"
            else arg.to_s
            end
          }.join(", ")
          return "{#{func_name}(#{arg_list})}"
        end

        begin
          # Create child scope for function execution
          scope.child_scope

          func.call(*positional_args, locale: @bundle.locale, **options)
        rescue => e
          scope.add_error("Function error in #{func_name}: #{e.message}")
          "{#{func_name}()}"
        end
      end

      # Resolve select expressions
      private def resolve_select_expression(expr, scope)
        selector = expr.selector
        variants = expr.variants
        star_index = expr.star || 0

        # Resolve selector value
        selector_value = resolve_expression(selector, scope)

        # Find matching variant
        selected_variant = find_matching_variant(variants, selector_value, scope)

        # Use default variant if no match
        if selected_variant.nil? && star_index && star_index < variants.length
          selected_variant = variants[star_index]
        end

        if selected_variant
          resolve_pattern(selected_variant.value, scope)
        else
          scope.add_error("No variant found for selector: #{selector_value}")
          selector_value.to_s
        end
      end

      # Find a matching variant for the selector value
      private def find_matching_variant(variants, selector_value, scope)
        variants.find do |variant|
          key = variant.key
          key_value = resolve_expression(key, scope)

          case key
          when Parser::AST::NumberLiteral
            # Numeric comparison
            # If precision is 0, compare as integers
            # Otherwise compare as floats
            if selector_value.is_a?(Numeric) && key_value.is_a?(Numeric)
              if key.precision == 0
                # Integer comparison when precision is 0
                Integer(key_value) == Integer(selector_value)
              else
                # Float comparison when precision > 0
                key_value == selector_value
              end
            else
              # Fallback to string comparison if not both numeric
              key_value.to_s == selector_value.to_s
            end
          when Parser::AST::StringLiteral
            # String comparison - check for ICU plural category match
            if numeric_selector?(selector_value)
              # Try ICU plural rules matching first
              plural_category_match?(key_value, selector_value, scope) ||
                # Fall back to direct string comparison
                key_value.to_s == selector_value.to_s
            else
              # Direct string comparison for non-numeric selectors
              key_value.to_s == selector_value.to_s
            end
          else
            # General comparison
            key_value == selector_value
          end
        end
      end

      # Check if selector value is numeric for plural rules processing
      private def numeric_selector?(value)
        value.is_a?(Numeric) || (value.is_a?(String) && value.match?(/^\d+(\.\d+)?$/))
      end

      # Check if key matches selector via ICU plural rules
      private def plural_category_match?(key_str, selector_value, scope)
        # Convert selector to numeric if needed
        numeric_value =
          case selector_value
          when Numeric
            selector_value
          when String
            if selector_value.match?(/^\d+$/)
              Integer(selector_value)
            elsif selector_value.match?(/^\d+\.\d+$/)
              Float(selector_value)
            else
              return false
            end
          else
            return false
          end

        # Use bundle's locale for plural rules
        plural_rules = ICU4X::PluralRules.new(@bundle.locale)
        plural_category = plural_rules.select(numeric_value).to_s
        key_str.to_s == plural_category
      rescue => e
        scope.add_error("Plural rule error: #{e.message}")
        false
      end

      # Resolve term attributes
      private def resolve_term_attribute(term, attr, scope)
        attributes = term.attributes || {}
        attr_pattern = attributes[attr]

        if attr_pattern
          resolve_pattern(attr_pattern, scope)
        else
          scope.add_error("Unknown term attribute: #{term.id}.#{attr}")
          "{#{term.id}.#{attr}}"
        end
      end

      # Resolve message attributes
      private def resolve_message_attribute(message, attr, scope)
        attributes = message.attributes || {}
        attr_pattern = attributes[attr]

        if attr_pattern
          resolve_pattern(attr_pattern, scope)
        else
          scope.add_error("Unknown message attribute: #{message.id}.#{attr}")
          "{#{message.id}.#{attr}}"
        end
      end
    end
  end
end
