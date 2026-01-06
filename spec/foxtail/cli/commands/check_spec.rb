# frozen_string_literal: true

require "tempfile"

RSpec.describe Foxtail::CLI::Commands::Check do
  subject(:command) { Foxtail::CLI::Commands::Check.new }

  describe "#call" do
    context "with no files" do
      it "raises NoFilesError" do
        expect {
          command.call(files: [], quiet: true)
        }.to raise_error(Foxtail::CLI::NoFilesError, "No files specified")
      end
    end

    context "with valid FTL files" do
      it "reports no errors and does not raise" do
        Tempfile.create(%w[valid .ftl]) do |f|
          f.write("hello = Hello, world!\n")
          f.flush

          expect {
            command.call(files: [f.path], quiet: true)
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
            command.call(files: [f.path], quiet: true)
          }.to output(String).to_stdout
            .and raise_error(Foxtail::CLI::CheckError) {|e| expect(e.error_count).to eq(1) }
        end
      end

      it "outputs junk content with file path" do
        Tempfile.create(%w[invalid .ftl]) do |f|
          f.write("hello = Hi\nbad entry\n")
          f.flush

          expect {
            command.call(files: [f.path], quiet: true)
          }.to output(/#{Regexp.escape(f.path)}: syntax error: bad entry/).to_stdout
            .and raise_error(Foxtail::CLI::CheckError)
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
            command.call(files: [en_path, ja_path], quiet: true)
          }.not_to raise_error
        end
      end
    end
  end
end
