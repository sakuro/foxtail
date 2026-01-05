# frozen_string_literal: true

require "json"
require "pathname"

# Shared utilities for fluent.js compatibility testing
module FluentCompatBase
  PROJECT_ROOT = Pathname(__dir__).parent.parent.parent
  private_constant :PROJECT_ROOT

  FLUENT_JS_ROOT = PROJECT_ROOT / "fluent.js"
  public_constant :FLUENT_JS_ROOT

  module_function def load_json(json_path)
    content = json_path.read(encoding: "utf-8")
    JSON.parse(content)
  rescue JSON::ParserError => e
    raise StandardError, "Failed to parse JSON fixture #{json_path}: #{e.message}"
  end

  module_function def load_ftl(ftl_path) = ftl_path.read(encoding: "utf-8")

  # Find fixture pairs starting from .json files (expected output)
  # @param json_dir [Pathname] directory containing .json fixtures
  # @param ftl_dir [Pathname] directory containing .ftl source files
  # @param extra_fields [Hash] additional fields to include in each pair
  # @return [Array<Hash>] sorted array of fixture pairs
  module_function def find_fixture_pairs(json_dir:, ftl_dir:, **extra_fields)
    return [] unless json_dir.exist?

    pairs = []
    json_dir.glob("*.json").each do |json_path|
      ftl_path = ftl_dir / json_path.basename.sub_ext(".ftl")
      next unless ftl_path.exist?

      pairs << {
        name: json_path.basename(".json").to_s,
        ftl_path:,
        json_path:,
        **extra_fields
      }
    end

    pairs.sort_by {|pair| pair[:name] }
  end

  # Collect fixtures from multiple directories
  # @param configs [Array<Hash>] array of find_fixture_pairs arguments
  # @return [Array<Hash>] combined array of fixture pairs
  module_function def collect_fixtures(*configs)
    configs.flat_map {|config| find_fixture_pairs(**config) }
  end
end
