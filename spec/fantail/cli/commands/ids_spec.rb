# frozen_string_literal: true

require "json"
require "tempfile"

RSpec.describe Fantail::CLI::Commands::Ids do
  let(:cli) { Dry.CLI(Fantail::CLI::Commands::Ids.new) }
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  let(:ftl_content) do
    <<~FTL
      hello = Hello
      greeting = Hello, { $name }!
          .placeholder = Your name

      -brand = Firefox
          .short = Fx
    FTL
  end

  describe "#call" do
    context "with no files" do
      it "raises NoFilesError" do
        expect {
          cli.call(arguments: [], out:, err:)
        }.to raise_error(Fantail::CLI::NoFilesError, "No files specified")
      end
    end

    context "with default options" do
      it "outputs all message and term IDs" do
        Tempfile.create(%w[test .ftl]) do |f|
          f.write(ftl_content)
          f.flush

          cli.call(arguments: [f.path], out:, err:)
          expect(out.string).to eq("hello\ngreeting\n-brand\n")
        end
      end
    end

    context "with --only-messages option" do
      it "outputs only message IDs" do
        Tempfile.create(%w[test .ftl]) do |f|
          f.write(ftl_content)
          f.flush

          cli.call(arguments: [f.path, "--only-messages"], out:, err:)
          expect(out.string).to eq("hello\ngreeting\n")
        end
      end
    end

    context "with --only-terms option" do
      it "outputs only term IDs" do
        Tempfile.create(%w[test .ftl]) do |f|
          f.write(ftl_content)
          f.flush

          cli.call(arguments: [f.path, "--only-terms"], out:, err:)
          expect(out.string).to eq("-brand\n")
        end
      end
    end

    context "with --with-attributes option" do
      it "includes attribute names" do
        Tempfile.create(%w[test .ftl]) do |f|
          f.write(ftl_content)
          f.flush

          cli.call(arguments: [f.path, "--with-attributes"], out:, err:)
          expect(out.string).to eq("hello\ngreeting\ngreeting.placeholder\n-brand\n-brand.short\n")
        end
      end
    end

    context "with --json option" do
      it "outputs as JSON array" do
        Tempfile.create(%w[test .ftl]) do |f|
          f.write(ftl_content)
          f.flush

          cli.call(arguments: [f.path, "--json"], out:, err:)
          expect(JSON.parse(out.string)).to eq(%w[hello greeting -brand])
        end
      end
    end

    context "with multiple files" do
      it "combines IDs from all files" do
        Dir.mktmpdir do |dir|
          a_path = File.join(dir, "a.ftl")
          b_path = File.join(dir, "b.ftl")
          File.write(a_path, "msg-a = A\n")
          File.write(b_path, "msg-b = B\n")

          cli.call(arguments: [a_path, b_path], out:, err:)
          expect(out.string).to eq("msg-a\nmsg-b\n")
        end
      end
    end
  end
end
