# frozen_string_literal: true

require_relative "bundle/ast_converter"
require_relative "parser"

module Foxtail
  # Parse FTL source and convert to Bundle::AST
  # Public API for creating resources from FTL content
  class Resource
    include Enumerable

    attr_reader :entries
    attr_reader :errors

    # Parse FTL source string into a Resource
    def self.from_string(source, **options)
      parser = Parser.new
      parser_resource = parser.parse(source)

      converter = Bundle::ASTConverter.new(options)
      entries = converter.convert_resource(parser_resource)

      new(entries, errors: converter.errors)
    end

    # Parse FTL file into a Resource
    def self.from_file(path, **)
      source = File.read(path)
      from_string(source, **)
    end

    def initialize(entries, errors: [])
      @entries = entries
      @errors = errors
    end

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
      @entries.select {|entry| entry["id"] && !entry["id"].start_with?("-") }
    end

    # Get term entries (IDs starting with "-")
    def terms
      @entries.select {|entry| entry["id"]&.start_with?("-") }
    end

    # Find entry by ID
    def find(id)
      @entries.find {|entry| entry["id"] == id }
    end
  end
end
