# frozen_string_literal: true

module FluentJsCompatibility
  # Helper methods for running compatibility tests
  module TestHelper
    KNOWN_MISMATCHES = [
      # https://github.com/projectfluent/fluent.js/blob/9a183312d4db035d6002c93e03f0c169a58f3234/fluent-syntax/test/reference_test.js#L24-L28
      {category: :reference, name: "leading_dots"}
    ].freeze
    private_constant :KNOWN_MISMATCHES

    def parse_ftl(source, with_spans:)
      parser = Foxtail::Syntax::Parser.new(with_spans:)
      resource = parser.parse(source)
      resource.to_h
    end

    def process_junk_annotations!(ast)
      return unless ast["body"].is_a?(Array)

      ast["body"].map! do |entry|
        entry["type"] == "Junk" ? entry.merge("annotations" => []) : entry
      end
    end

    module_function def known_mismatch?(fixture) = KNOWN_MISMATCHES.include?(fixture.slice(:category, :name))
  end
end
