# frozen_string_literal: true

module FluentJsCompatibility
  # Helper methods for running compatibility tests
  module TestHelper
    KNOWN_INCOMPATIBILITIES = %w[leading_dots].freeze
    private_constant :KNOWN_INCOMPATIBILITIES

    def parse_ftl(source, with_spans:)
      parser = Foxtail::Parser.new(with_spans:)
      resource = parser.parse(source)
      resource.to_h
    end

    def process_junk_annotations!(ast)
      return unless ast["body"].is_a?(Array)

      ast["body"].map! do |entry|
        entry["type"] == "Junk" ? entry.merge("annotations" => []) : entry
      end
    end

    module_function def known_incompatibility?(fixture_name) = KNOWN_INCOMPATIBILITIES.include?(fixture_name)
  end
end
