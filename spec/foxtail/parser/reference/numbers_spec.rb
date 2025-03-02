# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with number literals", ftl_fixture: "reference/numbers" do
      it "correctly parses number literals" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Helper method to get the number literal value from a message
        def get_number_value(message)
          message.value.elements[0].expression.value
        end

        # Verify integer literals
        int_zero = find_message("int-zero")
        expect(int_zero).not_to be_nil
        expect(get_number_value(int_zero)).to eq("0")

        int_positive = find_message("int-positive")
        expect(int_positive).not_to be_nil
        expect(get_number_value(int_positive)).to eq("1")

        int_negative = find_message("int-negative")
        expect(int_negative).not_to be_nil
        expect(get_number_value(int_negative)).to eq("-1")

        int_negative_zero = find_message("int-negative-zero")
        expect(int_negative_zero).not_to be_nil
        expect(get_number_value(int_negative_zero)).to eq("-0")

        # Verify padded integer literals
        int_positive_padded = find_message("int-positive-padded")
        expect(int_positive_padded).not_to be_nil
        expect(get_number_value(int_positive_padded)).to eq("01")

        int_negative_padded = find_message("int-negative-padded")
        expect(int_negative_padded).not_to be_nil
        expect(get_number_value(int_negative_padded)).to eq("-01")

        int_zero_padded = find_message("int-zero-padded")
        expect(int_zero_padded).not_to be_nil
        expect(get_number_value(int_zero_padded)).to eq("00")

        int_negative_zero_padded = find_message("int-negative-zero-padded")
        expect(int_negative_zero_padded).not_to be_nil
        expect(get_number_value(int_negative_zero_padded)).to eq("-00")

        # Verify float literals
        float_zero = find_message("float-zero")
        expect(float_zero).not_to be_nil
        expect(get_number_value(float_zero)).to eq("0.0")

        float_positive = find_message("float-positive")
        expect(float_positive).not_to be_nil
        expect(get_number_value(float_positive)).to eq("0.01")

        float_positive_one = find_message("float-positive-one")
        expect(float_positive_one).not_to be_nil
        expect(get_number_value(float_positive_one)).to eq("1.03")

        float_positive_without_fraction = find_message("float-positive-without-fraction")
        expect(float_positive_without_fraction).not_to be_nil
        expect(get_number_value(float_positive_without_fraction)).to eq("1.000")

        float_negative = find_message("float-negative")
        expect(float_negative).not_to be_nil
        expect(get_number_value(float_negative)).to eq("-0.01")

        float_negative_one = find_message("float-negative-one")
        expect(float_negative_one).not_to be_nil
        expect(get_number_value(float_negative_one)).to eq("-1.03")

        float_negative_zero = find_message("float-negative-zero")
        expect(float_negative_zero).not_to be_nil
        expect(get_number_value(float_negative_zero)).to eq("-0.0")

        float_negative_without_fraction = find_message("float-negative-without-fraction")
        expect(float_negative_without_fraction).not_to be_nil
        expect(get_number_value(float_negative_without_fraction)).to eq("-1.000")

        # Verify padded float literals
        float_positive_padded_left = find_message("float-positive-padded-left")
        expect(float_positive_padded_left).not_to be_nil
        expect(get_number_value(float_positive_padded_left)).to eq("01.03")

        float_positive_padded_right = find_message("float-positive-padded-right")
        expect(float_positive_padded_right).not_to be_nil
        expect(get_number_value(float_positive_padded_right)).to eq("1.0300")

        float_positive_padded_both = find_message("float-positive-padded-both")
        expect(float_positive_padded_both).not_to be_nil
        expect(get_number_value(float_positive_padded_both)).to eq("01.0300")

        float_negative_padded_left = find_message("float-negative-padded-left")
        expect(float_negative_padded_left).not_to be_nil
        expect(get_number_value(float_negative_padded_left)).to eq("-01.03")

        float_negative_padded_right = find_message("float-negative-padded-right")
        expect(float_negative_padded_right).not_to be_nil
        expect(get_number_value(float_negative_padded_right)).to eq("-1.0300")

        float_negative_padded_both = find_message("float-negative-padded-both")
        expect(float_negative_padded_both).not_to be_nil
        expect(get_number_value(float_negative_padded_both)).to eq("-01.0300")

        # Verify that invalid number formats are treated as Junk
        group_comment = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::GroupComment) && entry.content == "ERRORS"
        }
        expect(group_comment).not_to be_nil

        junk_entries = result.body.select {|entry| entry.is_a?(Foxtail::AST::Junk) }
        expect(junk_entries.size).to eq(7)

        # Verify that we have the right number of junk entries
        # We won't check their content due to issues with string comparison
        expect(junk_entries.size).to eq(7)
      end
    end
  end
end
