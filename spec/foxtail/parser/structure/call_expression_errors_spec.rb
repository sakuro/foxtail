# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with call expression errors", ftl_fixture: "structure/call_expression_errors" do
      it "parses as junk with error annotations" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains three Junk entries
        expect(result.body.size).to eq(3)
        expect(result.body.all?(Foxtail::AST::Junk)).to be true

        # Verify the first Junk entry (non-uppercase function name)
        junk1 = result.body[0]
        expect(junk1.content).to eq("err01 = { no-caps-name() }\n")
        expect(junk1.annotations.size).to eq(1)
        expect(junk1.annotations[0].code).to eq("E0008")
        expect(junk1.annotations[0].message).to include("The callee has to be a function")

        # Verify the second Junk entry (numeric named argument)
        junk2 = result.body[1]
        expect(junk2.content).to eq("err02 = { BUILTIN(2: \"foo\") }\n")
        expect(junk2.annotations.size).to eq(1)
        expect(junk2.annotations[0].code).to eq("E0009")
        expect(junk2.annotations[0].message).to include("The argument must be a message reference")

        # Verify the third Junk entry (non-literal argument value)
        junk3 = result.body[2]
        expect(junk3.content).to eq("err03 = { BUILTIN(key: foo) }\n")
        expect(junk3.annotations.size).to eq(1)
        expect(junk3.annotations[0].code).to eq("E0014")
        expect(junk3.annotations[0].message).to include("Expected literal")
      end
    end
  end
end
