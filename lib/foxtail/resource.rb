# frozen_string_literal: true

module Foxtail
  # Parse FTL source and convert to Bundle::AST
  # Public API for creating resources from FTL content
  class Resource
    include Enumerable

    # @return [Array<Hash>] Parsed FTL entries (messages and terms)
    attr_reader :entries

    # @return [Array<Hash>] Parse errors encountered during processing
    attr_reader :errors

    # Parse FTL source string into a Resource
    #
    # @param source [String] FTL source text to parse
    # @param skip_junk [Boolean] Skip invalid entries (default: true)
    # @param skip_comments [Boolean] Skip comment entries (default: true)
    # @return [Foxtail::Resource] New resource with parsed entries
    # @raise [ArgumentError] if source is not a string
    #
    # @example Parse FTL content
    #   source = <<~FTL
    #     hello = Hello, {$name}!
    #     goodbye = Goodbye!
    #   FTL
    #   resource = Foxtail::Resource.from_string(source)
    def self.from_string(source, skip_junk: true, skip_comments: true)
      parser = Parser.new
      parser_resource = parser.parse(source)

      converter = Bundle::ASTConverter.new(skip_junk:, skip_comments:)
      entries = converter.convert_resource(parser_resource)

      new(entries, errors: converter.errors)
    end

    # Parse FTL file into a Resource
    #
    # @param path [Pathname] Path to FTL file
    # @param skip_junk [Boolean] Skip invalid entries (default: true)
    # @param skip_comments [Boolean] Skip comment entries (default: true)
    # @return [Foxtail::Resource] New resource with parsed entries
    def self.from_file(path, skip_junk: true, skip_comments: true)
      source = path.read
      from_string(source, skip_junk:, skip_comments:)
    end

    def initialize(entries, errors: [])
      @entries = entries
      @errors = errors
    end

    private_class_method :new

    # Check if resource has any entries
    def empty?
      @entries.empty?
    end

    # Get the number of entries
    def size
      @entries.size
    end

    # Iterate over entries
    def each(&)
      @entries.each(&)
    end

    # Get entries by type
    def messages
      @entries.select {|entry| entry[:id] && !entry[:id].start_with?("-") }
    end

    # Get term entries (IDs starting with "-")
    def terms
      @entries.select {|entry| entry[:id]&.start_with?("-") }
    end

    # Find entry by ID
    def find(id)
      @entries.find {|entry| entry[:id] == id }
    end
  end
end
