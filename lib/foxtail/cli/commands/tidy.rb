# frozen_string_literal: true

module Foxtail
  # Command-line interface for Foxtail
  module CLI
    module Commands
      # Format FTL files with consistent style
      class Tidy < Dry::CLI::Command
        desc "Format FTL files with consistent style"

        argument :files, type: :array, required: true, desc: "FTL files to format"

        option :write, type: :flag, default: false, aliases: ["-w"], desc: "Write result back to source file"
        option :check, type: :flag, default: false, aliases: ["-c"], desc: "Check if files are formatted (for CI)"
        option :diff, type: :flag, default: false, aliases: ["-d"], desc: "Show diff instead of formatted output"
        option :with_junk, type: :flag, default: false, desc: "Allow formatting files with syntax errors"

        # Execute the tidy command
        # @param files [Array<String>] FTL files to format
        # @param write [Boolean] Write result back to source file
        # @param check [Boolean] Check if files are formatted (for CI)
        # @param diff [Boolean] Show diff instead of formatted output
        # @param with_junk [Boolean] Allow formatting files with syntax errors
        # @return [void]
        def call(files:, write:, check:, diff:, with_junk:, **)
          raise Foxtail::CLI::NoFilesError if files.empty?

          files_with_errors = []
          files_needing_format = []
          multiple_files = files.size > 1

          files.each do |file|
            result = process_file(file, write:, check:, diff:, with_junk:, multiple_files:)
            case result
            when :has_errors
              files_with_errors << file
            when :needs_format
              files_needing_format << file
            end
          end

          raise Foxtail::CLI::TidyError, files_with_errors unless files_with_errors.empty?
          raise Foxtail::CLI::TidyCheckError, files_needing_format if check && !files_needing_format.empty?
        end

        private def process_file(path, write:, check:, diff:, with_junk:, multiple_files:)
          content = File.read(path)
          parser = Foxtail::Parser.new
          resource = parser.parse(content)

          # Check for Junk entries (syntax errors)
          has_junk = resource.body.any?(Parser::AST::Junk)
          return :has_errors if has_junk && !with_junk

          serializer = Foxtail::Serializer.new(with_junk:)
          formatted = serializer.serialize(resource)

          if check
            return :needs_format if content != formatted

            return :ok
          end

          if diff
            output_diff(path, content, formatted)
            return :ok
          end

          if write
            File.write(path, formatted) if content != formatted
            return :ok
          end

          # Default: output to stdout
          output_formatted(path, formatted, multiple_files)
          :ok
        end

        private def output_formatted(path, formatted, multiple_files)
          if multiple_files
            puts "==> #{path} <=="
            puts formatted
          else
            print formatted
          end
        end

        private def output_diff(path, original, formatted)
          return if original == formatted

          require "tempfile"

          Tempfile.create(["original", ".ftl"]) do |orig_file|
            Tempfile.create(["formatted", ".ftl"]) do |fmt_file|
              orig_file.write(original)
              orig_file.flush
              fmt_file.write(formatted)
              fmt_file.flush

              # Use diff command with file path labels
              system("diff", "-u", "--label", path, orig_file.path, "--label", "#{path} (formatted)", fmt_file.path)
            end
          end
        end
      end
    end
  end
end
