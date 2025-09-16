# frozen_string_literal: true

module Foxtail
  module CLDR
    module Extractor
      # Base class for extractors that generate a single file from supplemental CLDR data
      #
      # This class handles extractors that process supplemental data (not locale-specific)
      # and generate one output file in the root output directory. Examples include
      # locale aliases, parent locales, and metazone mappings.
      #
      # @see Base
      class SingleFile < Base
        # Extract and generate the single output file
        #
        # This method coordinates the extraction process by calling extract_data from subclasses
        # and handling file writing and logging.
        def extract
          extractor_name = self.class.name.split("::").last
          CLDR.logger.info "Extracting #{extractor_name}..."

          data = extract_data
          filename = data_filename
          write_single_file(filename, data)

          data_description = describe_data(data)
          CLDR.logger.info "#{extractor_name} extraction complete (#{data_description})"

          data
        end

        # Write data to a single YAML file in the output directory root
        #
        # @param filename [String] The output filename (e.g., "locale_aliases.yml")
        # @param data [Hash] The data to write
        private def write_single_file(filename, data)
          file_path = @output_dir + filename

          yaml_data = {
            "generated_at" => Time.now.utc.iso8601,
            "cldr_version" => Foxtail::CLDR::SOURCE_VERSION
          }

          # Merge in the data, preserving its structure
          if data.is_a?(Hash)
            yaml_data.merge!(data)
          else
            yaml_data["data"] = data
          end

          # Skip writing if only generated_at differs
          if should_skip_write?(file_path, yaml_data)
            return
          end

          @output_dir.mkpath # Ensure output directory exists
          CLDR.logger.debug "Writing #{relative_path(file_path)}"
          file_path.write(yaml_data.to_yaml)
        end

        # Automatically derive data filename from class name using inflector
        private def data_filename
          # Get the class name without module prefix (e.g., "LocaleAliases")
          # Handle anonymous classes (for testing)
          class_name = self.class.name ? self.class.name.split("::").last : "data"
          # Convert to snake_case and add .yml extension
          "#{inflector.underscore(class_name)}.yml"
        end

        # Abstract method - subclasses must implement this to return the data hash
        # @return [Hash] The data to be written to the output file
        private def extract_data
          raise NotImplementedError, "Subclasses must implement extract_data"
        end

        # Generate a description of the extracted data for logging
        # Subclasses can override this to provide more specific descriptions
        # @param data [Hash] The extracted data
        # @return [String] Description for logging
        private def describe_data(data)
          if data.is_a?(Hash) && data.size == 1
            key, value = data.first
            case value
            when Hash
              "#{value.size} #{key.tr('_', ' ')}"
            when Array
              "#{value.size} #{key.tr('_', ' ')}"
            else
              key.tr('_', ' ')
            end
          else
            "#{data.size} items" if data.respond_to?(:size)
          end
        end
      end
    end
  end
end
