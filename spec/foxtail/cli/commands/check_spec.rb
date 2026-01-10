# frozen_string_literal: true

require "tempfile"

RSpec.describe Foxtail::CLI::Commands::Check do
  let(:cli) { Dry.CLI(Foxtail::CLI::Commands::Check.new) }
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  describe "#call" do
    context "with no files" do
      it "raises NoFilesError" do
        expect {
          cli.call(arguments: [], out:, err:)
        }.to raise_error(Foxtail::CLI::NoFilesError, "No files specified")
      end
    end

    context "with valid FTL files" do
      it "reports no errors and does not raise" do
        Tempfile.create(%w[valid .ftl]) do |f|
          f.write("hello = Hello, world!\n")
          f.flush

          expect {
            cli.call(arguments: [f.path, "--quiet"], out:, err:)
          }.not_to raise_error
        end
      end
    end

    context "with invalid FTL files" do
      it "raises CheckError with error count" do
        Tempfile.create(%w[invalid .ftl]) do |f|
          f.write("hello = Hi\nbad entry\n")
          f.flush

          expect {
            cli.call(arguments: [f.path, "--quiet"], out:, err:)
          }.to raise_error(Foxtail::CLI::CheckError) {|e| expect(e.error_count).to eq(1) }
        end
      end

      it "outputs junk content with file path to stderr" do
        Tempfile.create(%w[invalid .ftl]) do |f|
          f.write("hello = Hi\nbad entry\n")
          f.flush

          expect {
            cli.call(arguments: [f.path, "--quiet"], out:, err:)
          }.to raise_error(Foxtail::CLI::CheckError)
          expect(err.string).to match(/#{Regexp.escape(f.path)}: syntax error: bad entry/)
        end
      end
    end

    context "with multiple files" do
      it "checks all files without raising when valid" do
        Dir.mktmpdir do |dir|
          en_path = File.join(dir, "en.ftl")
          ja_path = File.join(dir, "ja.ftl")
          File.write(en_path, "hello = Hello!\n")
          File.write(ja_path, "hello = こんにちは！\n")

          expect {
            cli.call(arguments: [en_path, ja_path, "--quiet"], out:, err:)
          }.not_to raise_error
        end
      end
    end

    context "without --quiet option" do
      it "outputs summary to stdout" do
        Tempfile.create(%w[valid .ftl]) do |f|
          f.write("hello = Hello!\n")
          f.flush

          cli.call(arguments: [f.path], out:, err:)
          expect(out.string).to include("1 file(s) checked, 0 error(s) found")
        end
      end
    end
  end
end
