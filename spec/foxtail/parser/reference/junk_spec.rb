# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with junk", ftl_fixture: "reference/junk" do
      it "correctly parses junk" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify the "Two adjacent Junks" group comment
        two_adjacent_junks = find_group_comment("Two adjacent Junks.")
        expect(two_adjacent_junks).not_to be_nil
        expect(two_adjacent_junks).to be_a(Foxtail::AST::GroupComment)

        # Verify that junk entries are correctly identified
        junk_entries = result.body.select {|entry| entry.is_a?(Foxtail::AST::Junk) }
        expect(junk_entries.size).to eq(7)

        # Verify the first junk entry
        expect(junk_entries[0].content).to include("err01 = {1x}")

        # Verify the second junk entry
        expect(junk_entries[1].content).to include("err02 = {2x}")

        # Verify the "A single Junk." comment
        single_junk_comment = find_comment("A single Junk.")
        expect(single_junk_comment).not_to be_nil
        expect(single_junk_comment).to be_a(Foxtail::AST::Comment)

        # Verify the third junk entry
        expect(junk_entries[2].content).to include("err03 = {1x")
        expect(junk_entries[2].content).to include("2")

        # Verify the second "A single Junk." comment
        single_junk_comment2 = result.body.select {|entry|
          entry.is_a?(Foxtail::AST::Comment) && entry.content == "A single Junk."
        }
        expect(single_junk_comment2.size).to eq(2)

        # Verify the fourth junk entry
        expect(junk_entries[3].content).to include("ą=Invalid identifier")
        expect(junk_entries[3].content).to include("ć=Another one")

        # Verify the "The COMMENT ends this junk." comment
        comment_ends_junk = find_comment("The COMMENT ends this junk.")
        expect(comment_ends_junk).not_to be_nil
        expect(comment_ends_junk).to be_a(Foxtail::AST::Comment)

        # Verify the fifth junk entry
        expect(junk_entries[4].content).to include("err04 = {")

        # Verify the "COMMENT" comment
        comment = find_comment("COMMENT")
        expect(comment).not_to be_nil
        expect(comment).to be_a(Foxtail::AST::Comment)

        # Verify the "The COMMENT ends this junk.\nThe closing brace is a separate Junk." comment
        comment_ends_junk2 = find_comment("The COMMENT ends this junk.\nThe closing brace is a separate Junk.")
        expect(comment_ends_junk2).not_to be_nil
        expect(comment_ends_junk2).to be_a(Foxtail::AST::Comment)

        # Verify the sixth junk entry
        expect(junk_entries[5].content).to include("err04 = {")

        # Verify the second "COMMENT" comment
        comment2 = result.body.select {|entry| entry.is_a?(Foxtail::AST::Comment) && entry.content == "COMMENT" }
        expect(comment2.size).to eq(2)

        # Verify the seventh junk entry
        expect(junk_entries[6].content).to include("}")
      end
    end
  end
end
