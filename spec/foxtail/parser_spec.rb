# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  let(:parser) { described_class.new }

  describe "simple parsing" do
    it "parses empty resources" do
      result = parser.parse("")
      expect(result).to be_a(Foxtail::Parser::AST::Resource)
      expect(result.body).to be_empty
    end

    it "parses simple messages" do
      result = parser.parse("hello = Hello world")
      expect(result).to be_a(Foxtail::Parser::AST::Resource)
      expect(result.body.length).to eq(1)
      
      message = result.body.first
      expect(message).to be_a(Foxtail::Parser::AST::Message)
      expect(message.id.name).to eq("hello")
      expect(message.value).to be_a(Foxtail::Parser::AST::Pattern)
      expect(message.value.elements.length).to eq(1)
      expect(message.value.elements.first).to be_a(Foxtail::Parser::AST::TextElement)
      expect(message.value.elements.first.value).to eq("Hello world")
    end

    it "parses terms" do
      result = parser.parse("-brand = Firefox")
      expect(result).to be_a(Foxtail::Parser::AST::Resource)
      expect(result.body.length).to eq(1)
      
      term = result.body.first
      expect(term).to be_a(Foxtail::Parser::AST::Term)
      expect(term.id.name).to eq("brand")
    end

    it "parses comments" do
      result = parser.parse("# This is a comment")
      expect(result).to be_a(Foxtail::Parser::AST::Resource)
      expect(result.body.length).to eq(1)
      
      comment = result.body.first
      expect(comment).to be_a(Foxtail::Parser::AST::Comment)
      expect(comment.content).to eq("This is a comment")
    end
  end

  describe "error handling" do
    it "creates junk for invalid entries" do
      result = parser.parse("invalid entry")
      expect(result).to be_a(Foxtail::Parser::AST::Resource)
      expect(result.body.length).to eq(1)
      
      junk = result.body.first
      expect(junk).to be_a(Foxtail::Parser::AST::Junk)
      expect(junk.content).to include("invalid entry")
      expect(junk.annotations).not_to be_empty
    end
  end

  describe "to_h serialization" do
    it "serializes parsed AST to hash" do
      result = parser.parse("hello = Hello world")
      hash = result.to_h
      
      expect(hash["type"]).to eq("Resource")
      expect(hash["body"]).to be_a(Array)
      expect(hash["body"].length).to eq(1)
      expect(hash["body"][0]["type"]).to eq("Message")
      expect(hash["body"][0]["id"]["name"]).to eq("hello")
    end
  end
end