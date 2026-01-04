# frozen_string_literal: true

module Foxtail
  # Parse FTL source into Bundle::AST entries
  # Public API for creating resources from FTL content
  #
  # This class uses the runtime parser (Bundle::Parser) which is optimized
  # for performance and directly produces Bundle::AST structures.
  # Invalid entries are silently skipped (error recovery).
  # Comments are not preserved (runtime optimization).
  #
  # For full AST with source positions, comments, and error details,
  # use Syntax::Parser instead.
  class Resource
    include Enumerable

    # @return [Array<Bundle::AST::Message, Bundle::AST::Term>] Parsed FTL entries (messages and terms)
    attr_reader :entries

    # Parse FTL source string into a Resource
    #
    # @param source [String] FTL source text to parse
    # @return [Foxtail::Resource] New resource with parsed entries
    #
    # @example Parse FTL content
    #   source = <<~FTL
    #     hello = Hello, {$name}!
    #     goodbye = Goodbye!
    #   FTL
    #   resource = Foxtail::Resource.from_string(source)
    def self.from_string(source)
      parser = Bundle::Parser.new
      entries = parser.parse(source)

      new(entries)
    end

    # Parse FTL file into a Resource
    #
    # @param path [Pathname] Path to FTL file
    # @return [Foxtail::Resource] New resource with parsed entries
    def self.from_file(path)
      source = path.read
      from_string(source)
    end

    def initialize(entries)
      @entries = entries
    end

    private_class_method :new

    # Check if resource has any entries
    # @return [Boolean]
    def empty? = @entries.empty?

    # Get the number of entries
    # @return [Integer]
    def size = @entries.size

    # Iterate over entries
    # @return [self]
    def each(&)
      @entries.each(&)
      self
    end

    # Get message entries (IDs not starting with "-")
    # @return [Array<Bundle::AST::Message>]
    def messages = @entries.select {|entry| entry.id && !entry.id.start_with?("-") }

    # Get term entries (IDs starting with "-")
    # @return [Array<Bundle::AST::Term>]
    def terms = @entries.select {|entry| entry.id&.start_with?("-") }

    # Find entry by ID
    # @return [Bundle::AST::Message, Bundle::AST::Term, nil]
    def find(id) = @entries.find {|entry| entry.id == id }
  end
end
