# frozen_string_literal: true

require "json"
require "tempfile"

RSpec.describe Foxtail::CLI::Commands::Parse do
  subject(:command) { Foxtail::CLI::Commands::Parse.new }

  describe "#call" do
    context "with no files" do
      it "raises NoFilesError" do
        expect {
          command.call(files: [], with_spans: false)
        }.to raise_error(Foxtail::CLI::NoFilesError, "No files specified")
      end
    end

    context "with valid FTL file" do
      it "outputs JSON AST" do
        Tempfile.create(%w[valid .ftl]) do |f|
          f.write("hello = Hello, world!\n")
          f.flush

          output = capture_stdout { command.call(files: [f.path], with_spans: false) }
          result = JSON.parse(output)

          expect(result["file"]).to eq(f.path)
          expect(result["ast"]["type"]).to eq("Resource")
          expect(result["ast"]["body"].first["type"]).to eq("Message")
          expect(result["ast"]["body"].first["id"]["name"]).to eq("hello")
        end
      end

      it "excludes span information by default" do
        Tempfile.create(%w[valid .ftl]) do |f|
          f.write("hello = Hi\n")
          f.flush

          output = capture_stdout { command.call(files: [f.path], with_spans: false) }
          result = JSON.parse(output)

          expect(result["ast"]["body"].first).not_to have_key("span")
        end
      end

      it "includes span information when --with-spans is specified" do
        Tempfile.create(%w[valid .ftl]) do |f|
          f.write("hello = Hi\n")
          f.flush

          output = capture_stdout { command.call(files: [f.path], with_spans: true) }
          result = JSON.parse(output)

          expect(result["ast"]["body"].first["span"]).to include("start", "end")
        end
      end
    end

    context "with multiple files" do
      it "outputs array of ASTs" do
        Dir.mktmpdir do |dir|
          en_path = File.join(dir, "en.ftl")
          ja_path = File.join(dir, "ja.ftl")
          File.write(en_path, "hello = Hello!\n")
          File.write(ja_path, "hello = こんにちは！\n")

          output = capture_stdout { command.call(files: [en_path, ja_path], with_spans: false) }
          result = JSON.parse(output)

          expect(result).to be_an(Array)
          expect(result.size).to eq(2)
          expect(result[0]["file"]).to eq(en_path)
          expect(result[1]["file"]).to eq(ja_path)
        end
      end
    end

    context "with file containing junk" do
      it "includes junk entries in AST" do
        Tempfile.create(%w[junk .ftl]) do |f|
          f.write("hello = Hi\nbad entry\n")
          f.flush

          output = capture_stdout { command.call(files: [f.path], with_spans: false) }
          result = JSON.parse(output)

          types = result["ast"]["body"].map {|e| e["type"] }
          expect(types).to include("Junk")
        end
      end
    end
  end

  private def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
