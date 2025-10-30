# frozen_string_literal: true

module Foxtail
  class Bundle
    # Pattern resolution engine
    # Corresponds to fluent-bundle/src/resolver.ts
    class Resolver
      def initialize(bundle)
        @bundle = bundle
      end

      # Resolve a pattern with the given scope
      def resolve_pattern(pattern, scope)
        case pattern
        when String
          pattern
        when Array
          resolve_complex_pattern(pattern, scope)
        when Hash
          # Single expression (shouldn't normally happen in patterns)
          resolve_expression(pattern, scope)
        else
          pattern.to_s
        end
      end

      # Resolve a complex pattern (array of elements)
      def resolve_complex_pattern(elements, scope)
        elements.map {|element| resolve_pattern_element(element, scope) }.join
      end

      # Resolve individual pattern elements
      def resolve_pattern_element(element, scope)
        case element
        when String
          element
        when Hash
          result = resolve_expression(element, scope)
          # Convert resolved values to displayable strings
          case result
          when Numeric
            # For numeric values in patterns, format for display
            if element["precision"] && element["precision"] > 0
              format_number(result, element["precision"])
            else
              result.to_s
            end
          else
            result.to_s
          end
        else
          element.to_s
        end
      end

      # Resolve expressions (variables, terms, messages, functions, etc.)
      def resolve_expression(expr, scope)
        case expr["type"]
        when "str"
          expr["value"].to_s
        when "num"
          # Return raw numeric value, not formatted string
          expr["value"]
        when "var"
          resolve_variable_reference(expr, scope)
        when "term"
          resolve_term_reference(expr, scope)
        when "mesg"
          resolve_message_reference(expr, scope)
        when "func"
          resolve_function_call(expr, scope)
        when "select"
          resolve_select_expression(expr, scope)
        else
          scope.add_error("Unknown expression type: #{expr["type"]}")
          "{#{expr["type"]}}"
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

      # Resolve variable references
      private def resolve_variable_reference(expr, scope)
        name = expr["name"]
        expr["attr"] # Future: attribute access

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
        name = expr["name"]
        attr = expr["attr"]

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
        result = if attr
                   # Future: resolve attribute
                   resolve_term_attribute(term, attr, scope)
                 else
                   resolve_pattern(term["value"], scope)
                 end

        scope.release(name)
        result
      end

      # Resolve message references
      private def resolve_message_reference(expr, scope)
        name = expr["name"]
        attr = expr["attr"]

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
        result = if attr
                   # Future: resolve attribute
                   resolve_message_attribute(message, attr, scope)
                 else
                   resolve_pattern(message["value"], scope)
                 end

        scope.release(name)
        result
      end

      # Resolve function calls
      private def resolve_function_call(expr, scope)
        func_name = expr["name"]
        args = expr["args"] || []

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
          if arg["type"] == "narg"
            # Named argument - add to options hash
            key = arg["name"].to_sym
            value = resolve_expression(arg["value"], scope)
            options[key] = value
          else
            # Positional argument
            positional_args << resolve_expression(arg, scope)
          end
        end

        # If arguments resolution generated errors, fail the entire function call
        if scope.errors.length > initial_error_count
          arg_list = args.map {|arg|
            case arg["type"]
            when "var" then "$#{arg["name"]}"
            when "narg" then "#{arg["name"]}: #{arg["value"]}"
            else arg.to_s
            end
          }.join(", ")
          return "{#{func_name}(#{arg_list})}"
        end

        begin
          # Create child scope for function execution
          scope.child_scope

          # Try each locale in bundle's locale chain
          last_error = nil

          @bundle.locales.each do |locale|
            result = func.call(*positional_args, locale:, **options)
            return result
          rescue => e
            # For any errors (including CLDRDataNotAvailable), continue to next locale
            last_error = e
            next
          end

          # If all locales failed, raise the last error
          raise last_error if last_error

          # This shouldn't happen, but just in case
          "{#{func_name}()}"
        rescue => e
          scope.add_error("Function error in #{func_name}: #{e.message}")
          "{#{func_name}()}"
        end
      end

      # Resolve select expressions
      private def resolve_select_expression(expr, scope)
        selector = expr["selector"]
        variants = expr["variants"]
        star_index = expr["star"] || 0

        # Resolve selector value
        selector_value = resolve_expression(selector, scope)

        # Find matching variant
        selected_variant = find_matching_variant(variants, selector_value, scope)

        # Use default variant if no match
        if selected_variant.nil? && star_index && star_index < variants.length
          selected_variant = variants[star_index]
        end

        if selected_variant
          resolve_pattern(selected_variant["value"], scope)
        else
          scope.add_error("No variant found for selector: #{selector_value}")
          selector_value.to_s
        end
      end

      # Find a matching variant for the selector value
      private def find_matching_variant(variants, selector_value, scope)
        variants.find do |variant|
          key = variant["key"]
          key_value = resolve_expression(key, scope)

          case key["type"]
          when "num"
            # Numeric comparison
            # If precision is 0, compare as integers
            # Otherwise compare as floats
            if selector_value.is_a?(Numeric) && key_value.is_a?(Numeric)
              if key["precision"] == 0
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
          when "str"
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
        value.is_a?(Numeric) ||
          (value.is_a?(String) && value.match?(/^\d+(\.\d+)?$/))
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

        # Try each locale in the bundle's chain for plural rules
        @bundle.locales.each do |locale|
          plural_rules = Foxtail::CLDR::Repository::PluralRules.new(locale)
          plural_category = plural_rules.select(numeric_value)
          return key_str.to_s == plural_category
        rescue
          # If plural rule evaluation fails for this locale, try next
          next
        end
        # If all locales failed, add error and return false
        scope.add_error("Plural rule error: no matching locale found")
        false
      end

      # Resolve term attributes (future implementation)
      private def resolve_term_attribute(term, attr, scope)
        attributes = term["attributes"] || {}
        attr_pattern = attributes[attr]

        if attr_pattern
          resolve_pattern(attr_pattern, scope)
        else
          scope.add_error("Unknown term attribute: #{term["id"]}.#{attr}")
          "{#{term["id"]}.#{attr}}"
        end
      end

      # Resolve message attributes (future implementation)
      private def resolve_message_attribute(message, attr, scope)
        attributes = message["attributes"] || {}
        attr_pattern = attributes[attr]

        if attr_pattern
          resolve_pattern(attr_pattern, scope)
        else
          scope.add_error("Unknown message attribute: #{message["id"]}.#{attr}")
          "{#{message["id"]}.#{attr}}"
        end
      end
    end
  end
end
