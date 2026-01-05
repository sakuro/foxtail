# frozen_string_literal: true

require "json"

module Foxtail
  # Command-line interface for Foxtail
  module CLI
    module Commands
      # Parse FTL files and output AST as JSON
      class Parse < Dry::CLI::Command
        desc "Parse FTL files and output AST as JSON"

        argument :files, type: :array, required: true, desc: "FTL files to parse"

        option :with_spans, type: :flag, default: false, desc: "Include span information in output"

        # Execute the parse command
        # @param files [Array<String>] FTL files to parse
        # @param with_spans [Boolean] Include span information
        # @return [void]
        def call(files:, with_spans:, **)
          raise Foxtail::CLI::NoFilesError if files.empty?

          results = files.map {|file| parse_file(Pathname(file), with_spans:) }

          output = files.size == 1 ? results.first : results
          puts JSON.pretty_generate(output)
        end

        private def parse_file(path, with_spans:)
          content = path.read
          parser = Foxtail::Syntax::Parser.new(with_spans:)
          resource = parser.parse(content)

          {
            "file" => path.to_s,
            "ast" => resource.to_h
          }
        end
      end
    end
  end
end
