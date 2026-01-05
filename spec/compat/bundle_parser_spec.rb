# frozen_string_literal: true

require_relative "../support/compat/bundle"

SYNTAX_FIXTURES = FluentCompatBase::FLUENT_JS_ROOT / "fluent-syntax" / "test" / "fixtures_structure"
BUNDLE_FIXTURES = FluentCompatBase::FLUENT_JS_ROOT / "fluent-bundle" / "test" / "fixtures_structure"

RSpec.describe "fluent-bundle Compatibility" do
  include FluentBundleCompatibility::TestHelper

  FluentCompatBase.collect_fixtures({json_dir: BUNDLE_FIXTURES, ftl_dir: SYNTAX_FIXTURES}).each do |fixture|
    context fixture[:name] do
      it "matches fluent-bundle JSON output" do
        expected_json = FluentCompatBase.load_json(fixture[:json_path])
        ftl_source = FluentCompatBase.load_ftl(fixture[:ftl_path])
        entries = parse_ftl(ftl_source)
        actual_json = convert_to_json(entries)

        expect(actual_json["body"].length).to eq(expected_json["body"].length),
          "Expected #{expected_json["body"].length} entries, got #{actual_json["body"].length}"

        actual_json["body"].each_with_index do |entry, index|
          expected_entry = expected_json["body"][index]
          expect(entry["id"]).to eq(expected_entry["id"]),
            "Entry #{index}: expected id '#{expected_entry["id"]}', got '#{entry["id"]}'"
        end
      end
    end
  end
end
