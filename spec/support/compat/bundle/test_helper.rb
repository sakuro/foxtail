# frozen_string_literal: true

require_relative "../base"

module FluentBundleCompatibility
  # Helper methods for fluent-bundle compatibility tests
  module TestHelper
    def parse_ftl(source)
      parser = Foxtail::Bundle::Parser.new
      parser.parse(source)
    end

    def convert_to_json(entries)
      ASTConverter.to_json_format(entries)
    end
  end
end
