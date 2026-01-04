# frozen_string_literal: true

require "json"

module Foxtail
  # Command-line interface for Foxtail
  module CLI
    module Commands
      # Extract message and term IDs from FTL files
      class Ids < Dry::CLI::Command
        desc "Extract message and term IDs from FTL files"

        argument :files, type: :array, required: true, desc: "FTL files to extract IDs from"

        option :only_messages, type: :flag, default: false, aliases: ["-m"], desc: "Show only message IDs"
        option :only_terms, type: :flag, default: false, aliases: ["-t"], desc: "Show only term IDs"
        option :with_attributes, type: :flag, default: false, aliases: ["-a"], desc: "Include attribute names"
        option :json, type: :flag, default: false, aliases: ["-j"], desc: "Output as JSON array"

        # Execute the ids command
        def call(files:, only_messages:, only_terms:, with_attributes:, json:, **)
          ids = []

          files.each do |file|
            ids.concat(extract_ids(file, only_messages:, only_terms:, with_attributes:))
          end

          if json
            puts JSON.pretty_generate(ids)
          else
            ids.each { puts _1 }
          end
        end

        private def extract_ids(path, only_messages:, only_terms:, with_attributes:)
          ids = []
          content = File.read(path)
          parser = Foxtail::Parser.new
          resource = parser.parse(content)

          resource.body.each do |entry|
            case entry
            when Foxtail::Parser::AST::Message
              next if only_terms

              ids << entry.id.name
              ids.concat(attribute_ids(entry)) if with_attributes
            when Foxtail::Parser::AST::Term
              next if only_messages

              ids << "-#{entry.id.name}"
              ids.concat(attribute_ids(entry, prefix: "-")) if with_attributes
            end
          end

          ids
        end

        private def attribute_ids(entry, prefix: "")
          entry.attributes.map { "#{prefix}#{entry.id.name}.#{_1.id.name}" }
        end
      end
    end

    register "ids", Commands::Ids
  end
end
