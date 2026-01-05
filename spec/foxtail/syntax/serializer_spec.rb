# frozen_string_literal: true

RSpec.describe Foxtail::Syntax::Serializer do
  subject(:serializer) { Foxtail::Syntax::Serializer.new(**options) }

  let(:options) { {} }
  let(:parser) { Foxtail::Syntax::Parser.new }

  def parse_and_serialize(ftl)
    resource = parser.parse(ftl)
    serializer.serialize(resource)
  end

  describe "#serialize" do
    context "with simple messages" do
      it "serializes a simple message" do
        result = parse_and_serialize("hello = Hello, world!\n")
        expect(result).to eq("hello = Hello, world!\n")
      end

      it "normalizes spacing around equals sign" do
        result = parse_and_serialize("hello=Hello\n")
        expect(result).to eq("hello = Hello\n")
      end
    end

    context "with variables" do
      it "serializes variable references" do
        result = parse_and_serialize("greeting = Hello, { $name }!\n")
        expect(result).to eq("greeting = Hello, { $name }!\n")
      end
    end

    context "with select expressions" do
      it "serializes select expressions on new line" do
        ftl = <<~FTL
          emails = { $count ->
              [one] one email
             *[other] { $count } emails
          }
        FTL
        result = parse_and_serialize(ftl)
        expect(result).to include("{ $count ->")
        expect(result).to include("[one]")
        expect(result).to include("*[other]")
      end
    end

    context "with terms" do
      it "serializes terms with dash prefix" do
        result = parse_and_serialize("-brand = Firefox\n")
        expect(result).to eq("-brand = Firefox\n")
      end

      it "serializes term references" do
        ftl = <<~FTL
          -brand = Firefox
          welcome = Welcome to { -brand }
        FTL
        result = parse_and_serialize(ftl)
        expect(result).to include("{ -brand }")
      end
    end

    context "with attributes" do
      it "serializes message attributes" do
        ftl = <<~FTL
          login =
              .placeholder = Email
              .title = Login form
        FTL
        result = parse_and_serialize(ftl)
        expect(result).to include(".placeholder = Email")
        expect(result).to include(".title = Login form")
      end
    end

    context "with comments" do
      it "serializes message comments" do
        ftl = <<~FTL
          # This is a comment
          hello = Hello
        FTL
        result = parse_and_serialize(ftl)
        expect(result).to include("# This is a comment")
      end

      it "serializes group comments with ##" do
        ftl = <<~FTL
          ## Group comment
          hello = Hello
        FTL
        result = parse_and_serialize(ftl)
        expect(result).to include("## Group comment")
      end

      it "serializes resource comments with ###" do
        ftl = <<~FTL
          ### Resource comment
          hello = Hello
        FTL
        result = parse_and_serialize(ftl)
        expect(result).to include("### Resource comment")
      end
    end

    context "with functions" do
      it "serializes function calls" do
        ftl = "amount = { NUMBER($value, style: \"currency\") }\n"
        result = parse_and_serialize(ftl)
        expect(result).to include("NUMBER($value, style: \"currency\")")
      end
    end

    context "with Junk entries" do
      let(:ftl) { "hello = Hi\nbad entry\n" }

      context "when with_junk is false (default)" do
        it "excludes Junk from output" do
          result = parse_and_serialize(ftl)
          expect(result).to eq("hello = Hi\n")
          expect(result).not_to include("bad entry")
        end
      end

      context "when with_junk is true" do
        let(:options) { {with_junk: true} }

        it "includes Junk in output" do
          result = parse_and_serialize(ftl)
          expect(result).to include("hello = Hi")
          expect(result).to include("bad entry")
        end
      end
    end
  end
end
