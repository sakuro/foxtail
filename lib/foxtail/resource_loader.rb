# frozen_string_literal: true

require_relative "parser"

module Foxtail
  # ResourceLoader loads FTL resources from files or strings
  class ResourceLoader
    def initialize(options={})
      @parser = Parser.new(options)
    end

    # Load FTL resource from a string
    def load_from_string(source, resource_id=nil)
      @parser.parse(source)
    end

    # Load FTL resource from a file
    def load_from_file(file_path, resource_id=nil)
      source = File.read(file_path)
      load_from_string(source, resource_id || file_path)
    end
  end
end
