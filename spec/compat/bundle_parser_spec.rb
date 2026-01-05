# frozen_string_literal: true

require "json"
require "pathname"

RSpec.describe Foxtail::Bundle::Parser do
  subject(:parser) { Foxtail::Bundle::Parser.new }

  # Convert Bundle::AST entries to fluent-bundle JSON format for comparison
  def to_fluent_bundle_format(entries)
    {
      "body" => entries.map {|entry| entry_to_json(entry) }
    }
  end

  def entry_to_json(entry)
    {
      "id" => entry.id.sub(/^-/, ""), # fluent-bundle strips the leading dash for terms
      "value" => value_to_json(entry.value),
      "attributes" => attributes_to_json(entry.attributes)
    }
  end

  def value_to_json(value)
    case value
    when String
      value
    when Array
      value.map {|element| element_to_json(element) }
    when nil
      nil
    else
      element_to_json(value)
    end
  end

  def element_to_json(element)
    case element
    when String
      element
    when Foxtail::Bundle::AST::VariableReference
      {"type" => "var", "name" => element.name}
    when Foxtail::Bundle::AST::MessageReference
      {"type" => "mesg", "name" => element.name, "attr" => element.attr}
    when Foxtail::Bundle::AST::TermReference
      {"type" => "term", "name" => element.name, "attr" => element.attr}
    when Foxtail::Bundle::AST::FunctionReference
      {"type" => "func", "name" => element.name, "args" => args_to_json(element.args)}
    when Foxtail::Bundle::AST::NumberLiteral
      {"type" => "numb", "value" => element.value, "precision" => element.precision}
    when Foxtail::Bundle::AST::StringLiteral
      {"type" => "str", "value" => element.value}
    when Foxtail::Bundle::AST::SelectExpression
      {
        "type" => "select",
        "selector" => element_to_json(element.selector),
        "variants" => element.variants.map {|v| variant_to_json(v) },
        "star" => element.star
      }
    else
      element.to_s
    end
  end

  def args_to_json(args)
    args.map do |arg|
      case arg
      when Foxtail::Bundle::AST::NamedArgument
        {"type" => "narg", "name" => arg.name, "value" => element_to_json(arg.value)}
      else
        element_to_json(arg)
      end
    end
  end

  def variant_to_json(variant)
    {"key" => element_to_json(variant.key), "value" => value_to_json(variant.value)}
  end

  def attributes_to_json(attributes)
    return {} if attributes.nil?

    attributes.transform_values {|v| value_to_json(v) }
  end

  describe "basic parsing" do
    it "parses simple messages" do
      ftl = "hello = Hello world"
      entries = parser.parse(ftl)

      expect(entries.length).to eq(1)
      expect(entries.first.id).to eq("hello")
      expect(entries.first.value).to eq("Hello world")
    end

    it "parses terms" do
      ftl = "-brand = Firefox"
      entries = parser.parse(ftl)

      expect(entries.length).to eq(1)
      expect(entries.first.id).to eq("-brand")
      expect(entries.first.value).to eq("Firefox")
    end
  end

  describe "fixture compatibility" do
    # Test a selection of fixtures that are representative of fluent-bundle's output format
    %w[
      blank_lines
      crlf
      empty_resource
      indent
      simple_message
    ].each do |fixture_name|
      context "with #{fixture_name} fixture" do
        let(:ftl_path) { Pathname("fluent.js/fluent-syntax/test/fixtures_structure/#{fixture_name}.ftl") }
        let(:json_path) { Pathname("fluent.js/fluent-bundle/test/fixtures_structure/#{fixture_name}.json") }
        let(:ftl_source) { ftl_path.read }
        let(:expected_json) { JSON.parse(json_path.read) }

        before do
          skip "Fixture files not found" unless ftl_path.exist? && json_path.exist?
        end

        it "produces compatible output structure" do
          entries = parser.parse(ftl_source)
          actual = to_fluent_bundle_format(entries)

          # Compare entry counts
          expect(actual["body"].length).to eq(expected_json["body"].length),
            "Expected #{expected_json["body"].length} entries, got #{actual["body"].length}"

          # Compare each entry's id
          actual["body"].each_with_index do |entry, index|
            expected_entry = expected_json["body"][index]
            expect(entry["id"]).to eq(expected_entry["id"]),
              "Entry #{index}: expected id '#{expected_entry["id"]}', got '#{entry["id"]}'"
          end
        end
      end
    end
  end

  describe "value type matching" do
    it "produces string for simple inline text" do
      entries = parser.parse("hello = Hello world")
      expect(entries.first.value).to be_a(String)
    end

    it "produces array for patterns with placeables" do
      entries = parser.parse("hello = Hello { $name }")
      expect(entries.first.value).to be_a(Array)
    end

    it "produces array for multiline patterns" do
      ftl = <<~FTL
        multiline =
            Line 1
            Line 2
      FTL
      entries = parser.parse(ftl)
      expect(entries.first.value).to be_a(Array)
    end
  end

  describe "attribute handling" do
    it "produces nil for messages without attributes" do
      entries = parser.parse("hello = Hello")
      expect(entries.first.attributes).to be_nil
    end

    it "produces hash for messages with attributes" do
      ftl = <<~FTL
        hello = Hello
            .tooltip = A tooltip
      FTL
      entries = parser.parse(ftl)
      expect(entries.first.attributes).to eq({"tooltip" => "A tooltip"})
    end
  end

  describe "error recovery" do
    it "skips invalid entries (fluent-bundle behavior)" do
      ftl = <<~FTL
        valid1 = Hello
        invalid entry
        valid2 = World
      FTL
      entries = parser.parse(ftl)

      expect(entries.length).to eq(2)
      expect(entries.map(&:id)).to eq(%w[valid1 valid2])
    end
  end
end
