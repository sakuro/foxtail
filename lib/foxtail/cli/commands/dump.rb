# frozen_string_literal: true

require "json"

module Foxtail
  # Command-line interface for Foxtail
  module CLI
    module Commands
      # Dump FTL files as AST in JSON format
      class Dump < Dry::CLI::Command
        desc "Dump FTL files as AST in JSON format"

        argument :files, type: :array, required: true, desc: "FTL files to dump"

        option :with_spans, type: :flag, default: false, desc: "Include span information in output"

        # Execute the dump command
        # @param files [Array<String>] FTL files to dump
        # @param with_spans [Boolean] Include span information
        # @return [void]
        def call(files:, with_spans:, **)
          raise Foxtail::CLI::NoFilesError if files.empty?

          results = files.map {|file| dump_file(Pathname(file), with_spans:) }

          output = files.size == 1 ? results.first : results
          out.puts JSON.pretty_generate(output)
        end

        private def dump_file(path, with_spans:)
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
