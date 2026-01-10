# frozen_string_literal: true

module Foxtail
  # Command-line interface for Foxtail
  module CLI
    module Commands
      # Check FTL files for syntax errors
      class Check < Dry::CLI::Command
        desc "Check FTL files for syntax errors"

        argument :files, type: :array, required: true, desc: "FTL files to check"

        option :quiet, type: :flag, default: false, aliases: ["-q"], desc: "Only show errors, no summary"

        # Execute the check command
        # @param files [Array<String>] FTL files to check
        # @param quiet [Boolean] Only show errors, no summary
        # @return [void]
        def call(files:, quiet:, **)
          raise Foxtail::CLI::NoFilesError if files.empty?

          total_errors = 0
          total_files = 0

          files.each do |file|
            errors = check_file(file)
            total_files += 1
            total_errors += errors.size

            errors.each do |error|
              err.puts error
            end
          end

          unless quiet
            out.puts
            out.puts "#{total_files} file(s) checked, #{total_errors} error(s) found"
          end

          raise Foxtail::CLI::CheckError, total_errors if total_errors > 0
        end

        private def check_file(path)
          errors = []
          content = File.read(path)
          parser = Foxtail::Syntax::Parser.new
          resource = parser.parse(content)

          resource.body.each do |entry|
            case entry
            when Foxtail::Syntax::Parser::AST::Junk
              errors << format_junk_error(path, entry)
            end
          end

          errors
        end

        private def format_junk_error(path, junk)
          first_line = junk.content.lines.first&.chomp || ""
          "#{path}: syntax error: #{first_line}"
        end
      end
    end
  end
end
