# frozen_string_literal: true

require "locale"
require_relative "bundle/ast"
require_relative "bundle/ast_converter"
require_relative "bundle/resolver"
require_relative "bundle/scope"
require_relative "functions"

module Foxtail
  # Main runtime class for message formatting
  # Corresponds to fluent-bundle/src/bundle.ts
  class Bundle
    attr_reader :locales
    attr_reader :messages
    attr_reader :terms
    attr_reader :functions
    attr_reader :use_isolating
    attr_reader :transform

    def initialize(locales, **options)
      # Accept only Locale instances for type safety
      @locales = Array(locales).each_with_object([]) {|locale, acc|
        unless locale.is_a?(Locale::Tag::Simple)
          raise ArgumentError, "All locales must be Locale instances " \
                               "(subclass of Locale::Tag::Simple), got: #{locale.class}"
        end
        acc << locale
      }.freeze

      @messages = {}  # id → Bundle::AST Message
      @terms = {}     # id → Bundle::AST Term
      @functions = options[:functions] || Functions.defaults
      @use_isolating = options.fetch(:use_isolating, true)
      @transform = options[:transform]
    end

    # Get primary locale for this bundle
    def locale
      @locales.first.to_s
    end

    # Add a resource to this bundle
    def add_resource(resource, **options)
      allow_overrides = options.fetch(:allow_overrides, false)

      resource.entries.each do |entry|
        # In fluent-bundle format, terms have '-' prefix in id
        if entry["id"]&.start_with?("-")
          add_term_entry(entry, allow_overrides)
        else
          add_message_entry(entry, allow_overrides)
        end
      end

      resource.errors
    end

    # Check if a message exists
    def message?(id)
      @messages.key?(id.to_s)
    end

    # Get a message by ID
    def message(id)
      @messages[id.to_s]
    end

    # Check if a term exists (private method in fluent-bundle)
    def term?(id)
      @terms.key?(id.to_s)
    end

    # Get a term by ID (private method in fluent-bundle)
    def term(id)
      @terms[id.to_s]
    end

    # Format a message with the given arguments
    def format(id, args={})
      message = message(id)
      return id.to_s unless message

      scope = Scope.new(self, args)
      resolver = Resolver.new(self)
      resolver.resolve_pattern(message["value"], scope)
      # For now, return just the result
      # In full implementation, would return [result, scope.errors]
    end

    # Format a pattern with the given arguments (using Resolver)
    def format_pattern(pattern, args={}, errors=nil)
      scope = Scope.new(self, args)
      resolver = Resolver.new(self)
      result = resolver.resolve_pattern(pattern, scope)

      # Copy errors to provided array if given
      errors&.concat(scope.errors)

      result
    end

    private def add_message_entry(entry, allow_overrides)
      id = entry["id"]
      if @messages.key?(id) && !allow_overrides
        # In full implementation, would add to errors
        return
      end

      @messages[id] = entry
    end

    private def add_term_entry(entry, allow_overrides)
      id = entry["id"]
      if @terms.key?(id) && !allow_overrides
        # In full implementation, would add to errors
        return
      end

      @terms[id] = entry
    end
  end
end
