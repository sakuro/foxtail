# frozen_string_literal: true

require "tempfile"

RSpec.describe Foxtail::CLI::Commands::Tidy do
  let(:cli) { Dry.CLI(Foxtail::CLI::Commands::Tidy.new) }
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
      it "outputs formatted content to stdout" do
        Tempfile.create(%w[valid .ftl]) do |f|
          f.write("hello=Hello\n")
          f.flush

          cli.call(arguments: [f.path], out:, err:)
          expect(out.string).to eq("hello = Hello\n")
        end
      end

      it "does not raise when file is already formatted" do
        Tempfile.create(%w[valid .ftl]) do |f|
          f.write("hello = Hello\n")
          f.flush

          expect {
            cli.call(arguments: [f.path], out:, err:)
          }.not_to raise_error
          expect(out.string).to eq("hello = Hello\n")
        end
      end
    end

    context "with multiple files" do
      it "outputs with file headers" do
        Dir.mktmpdir do |dir|
          a_path = File.join(dir, "a.ftl")
          b_path = File.join(dir, "b.ftl")
          File.write(a_path, "a = A\n")
          File.write(b_path, "b = B\n")

          cli.call(arguments: [a_path, b_path], out:, err:)
          expect(out.string).to match(/==> .*a\.ftl <==.*==> .*b\.ftl <==/m)
        end
      end
    end

    context "with --write option" do
      it "writes formatted content back to file" do
        Tempfile.create(%w[towrite .ftl]) do |f|
          f.write("hello=Hello\n")
          f.flush

          cli.call(arguments: [f.path, "--write"], out:, err:)
          expect(out.string).to be_empty
          expect(File.read(f.path)).to eq("hello = Hello\n")
        end
      end
    end

    context "with --check option" do
      it "does not raise when file is already formatted" do
        Tempfile.create(%w[formatted .ftl]) do |f|
          f.write("hello = Hello\n")
          f.flush

          expect {
            cli.call(arguments: [f.path, "--check"], out:, err:)
          }.not_to raise_error
        end
      end

      it "raises TidyCheckError when file needs formatting" do
        Tempfile.create(%w[unformatted .ftl]) do |f|
          f.write("hello=Hello\n")
          f.flush

          expect {
            cli.call(arguments: [f.path, "--check"], out:, err:)
          }.to raise_error(Foxtail::CLI::TidyCheckError)
        end
      end
    end

    context "with --diff option" do
      it "shows diff when file needs formatting" do
        Tempfile.create(%w[unformatted .ftl]) do |f|
          f.write("hello=Hello\n")
          f.flush

          cli.call(arguments: [f.path, "--diff"], out:, err:)
          expect(out.string).to include("-hello=Hello")
          expect(out.string).to include("+hello = Hello")
        end
      end
    end

    context "with syntax errors (Junk)" do
      it "raises TidyError by default" do
        Tempfile.create(%w[broken .ftl]) do |f|
          f.write("hello = Hi\nbad entry\n")
          f.flush

          expect {
            cli.call(arguments: [f.path], out:, err:)
          }.to raise_error(Foxtail::CLI::TidyError)
        end
      end

      it "includes Junk when --with-junk is specified" do
        Tempfile.create(%w[broken .ftl]) do |f|
          f.write("hello = Hi\nbad entry\n")
          f.flush

          cli.call(arguments: [f.path, "--with-junk"], out:, err:)
          expect(out.string).to match(/hello = Hi.*bad entry/m)
        end
      end
    end
  end
end
