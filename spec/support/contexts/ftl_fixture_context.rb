# frozen_string_literal: true

# Shared context for FTL fixture-based tests
# This context provides common setup for tests that use FTL fixtures.
# It loads the appropriate fixture files based on the ftl_fixture tag,
# initializes the parser, and makes the parse result available to the tests.
RSpec.shared_context "with ftl fixture" do
  # Get the base part of the file path from the tag
  let(:fixture_path_base) { self.class.metadata[:ftl_fixture] }

  # Generate paths for ftl and json files from the base path
  let(:ftl_file) { "spec/fixtures/#{fixture_path_base}.ftl" }
  let(:json_file) { "spec/fixtures/#{fixture_path_base}.json" }

  # Load file contents
  let(:source) { File.read(ftl_file) }
  let(:expected_json) { JSON.parse(File.read(json_file)) }

  # Parser and parse result
  let(:parser) { Foxtail::Parser.new }
  let(:result) { parser.parse(source) }

  # Helper methods for finding specific entries in the parsed result

  # Find a message by ID
  def find_message(id)
    result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == id }
  end

  # Find a term by ID
  def find_term(id)
    result.body.find {|entry| entry.is_a?(Foxtail::AST::Term) && entry.id.name == id }
  end

  # Find a comment by content
  def find_comment(content)
    result.body.find {|entry| entry.is_a?(Foxtail::AST::Comment) && entry.content == content }
  end

  # Find a group comment by content
  def find_group_comment(content)
    result.body.find {|entry| entry.is_a?(Foxtail::AST::GroupComment) && entry.content == content }
  end

  # Find a resource comment by content
  def find_resource_comment(content)
    result.body.find {|entry| entry.is_a?(Foxtail::AST::ResourceComment) && entry.content == content }
  end
end
