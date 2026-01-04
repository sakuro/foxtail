# frozen_string_literal: true

require "icu4x"

module Foxtail
  # Main runtime class for message formatting and localization.
  #
  # Bundle manages a collection of messages and terms for a single locale,
  # providing formatting capabilities with support for pluralization,
  # variable interpolation, and function calls.
  #
  # ICU4X handles locale fallback internally through the locale's parent chain
  # (e.g., ja-JP → ja → und), so only a single locale is needed.
  #
  # @example Basic usage
  #   locale = ICU4X::Locale.parse("en-US")
  #   bundle = Foxtail::Bundle.new(locale)
  #
  #   resource = Foxtail::Resource.from_string("hello = Hello, {$name}!")
  #   bundle.add_resource(resource)
  #
  #   result = bundle.format("hello", name: "World")
  #   # => "Hello, World!"
  #
  # @example With custom functions
  #   functions = Foxtail::Function.defaults.merge(
  #     "UPPER" => ->(str, **_opts) { str.upcase }
  #   )
  #   bundle = Foxtail::Bundle.new(locale, functions: functions)
  #
  # Corresponds to fluent-bundle/src/bundle.ts in the original JavaScript implementation.
  class Bundle
    # @return [ICU4X::Locale] The locale for this bundle
    attr_reader :locale
    # @return [Hash{String => Bundle::AST::Message}] Message entries indexed by ID
    attr_reader :messages
    # @return [Hash{String => Bundle::AST::Term}] Term entries indexed by ID
    attr_reader :terms
    # @return [Hash{String => #call}] Custom formatting functions
    attr_reader :functions
    # @return [#call, nil] Optional message transformation function
    attr_reader :transform

    # Create a new Bundle instance.
    #
    # @param locale [ICU4X::Locale] The locale for this bundle
    # @param functions [Hash{String => #call}] Custom formatting functions (defaults to NUMBER and DATETIME)
    # @param use_isolating [Boolean] Whether to use Unicode bidi isolation marks for placeables (default: true)
    # @param transform [#call, nil] Optional message transformation function (not currently implemented)
    # @raise [ArgumentError] if locale is not an ICU4X::Locale instance
    #
    # @example Basic bundle creation
    #   locale = ICU4X::Locale.parse("en-US")
    #   bundle = Foxtail::Bundle.new(locale)
    def initialize(locale, functions: Function.defaults, use_isolating: true, transform: nil)
      raise ArgumentError, "locale must be an ICU4X::Locale instance, got: #{locale.class}" unless locale.is_a?(ICU4X::Locale)

      @locale = locale
      @messages = {}  # id → Bundle::AST Message
      @terms = {}     # id → Bundle::AST Term
      @functions = functions
      @use_isolating = use_isolating
      @transform = transform
    end

    # @return [Boolean] Whether to use Unicode bidi isolation marks
    def use_isolating? = @use_isolating

    # Add a resource to this bundle
    #
    # @param resource [Resource] The resource to add
    # @param allow_overrides [Boolean] Whether to allow overriding existing messages/terms
    # @return [Array] Empty array (error recovery is handled during parsing)
    def add_resource(resource, allow_overrides: false)
      resource.entries.each do |entry|
        # In fluent-bundle format, terms have '-' prefix in id
        if entry.id&.start_with?("-")
          add_term_entry(entry, allow_overrides)
        else
          add_message_entry(entry, allow_overrides)
        end
      end

      [] # Runtime parser uses error recovery - no errors to return
    end

    # Check if a message exists
    # @return [Boolean]
    def message?(id) = @messages.key?(id.to_s)

    # Get a message by ID
    # @return [Bundle::AST::Message, nil]
    def message(id) = @messages[id.to_s]

    # Check if a term exists (private method in fluent-bundle)
    # @return [Boolean]
    def term?(id) = @terms.key?(id.to_s)

    # Get a term by ID (private method in fluent-bundle)
    # @return [Bundle::AST::Term, nil]
    def term(id) = @terms[id.to_s]

    # Format a message with the given arguments.
    # Keyword arguments are substituted into the message as variables.
    #
    # @param id [String, Symbol] Message identifier to format
    # @return [String] Formatted message string, or the id itself if message not found
    #
    # @example Basic message formatting
    #   bundle.format("hello", name: "Alice")
    #   # => "Hello, Alice!" (assuming message: hello = Hello, {$name}!)
    #
    # @example Pluralization
    #   bundle.format("emails", count: 1)
    #   # => "You have one email." (assuming plural message)
    def format(id, **)
      message = message(id)
      return id.to_s unless message

      scope = Scope.new(self, **)
      resolver = Resolver.new(self)
      resolver.resolve_pattern(message.value, scope)
      # For now, return just the result
      # In full implementation, would return [result, scope.errors]
    end

    # Format a pattern with the given arguments (using Resolver)
    # @return [String]
    def format_pattern(pattern, errors: nil, **)
      scope = Scope.new(self, **)
      resolver = Resolver.new(self)
      result = resolver.resolve_pattern(pattern, scope)

      # Copy errors to provided array if given
      errors&.concat(scope.errors)

      result
    end

    private def add_message_entry(entry, allow_overrides)
      id = entry.id
      if @messages.key?(id) && !allow_overrides
        # In full implementation, would add to errors
        return
      end

      @messages[id] = entry
    end

    private def add_term_entry(entry, allow_overrides)
      id = entry.id
      if @terms.key?(id) && !allow_overrides
        # In full implementation, would add to errors
        return
      end

      @terms[id] = entry
    end
  end
end
