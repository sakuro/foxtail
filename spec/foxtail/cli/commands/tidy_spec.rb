# frozen_string_literal: true

require "tempfile"

RSpec.describe Foxtail::CLI::Commands::Tidy do
  subject(:command) { Foxtail::CLI::Commands::Tidy.new }

  describe "#call" do
    context "with valid FTL files" do
      it "outputs formatted content to stdout" do
        Tempfile.create(%w[valid .ftl]) do |f|
          f.write("hello=Hello\n")
          f.flush

          expect {
            command.call(files: [f.path], write: false, check: false, diff: false, with_junk: false)
          }.to output("hello = Hello\n").to_stdout
        end
      end

      it "does not raise when file is already formatted" do
        Tempfile.create(%w[valid .ftl]) do |f|
          f.write("hello = Hello\n")
          f.flush

          expect {
            command.call(files: [f.path], write: false, check: false, diff: false, with_junk: false)
          }.to output("hello = Hello\n").to_stdout
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

          expect {
            command.call(files: [a_path, b_path], write: false, check: false, diff: false, with_junk: false)
          }.to output(/==> .*a\.ftl <==.*==> .*b\.ftl <==/m).to_stdout
        end
      end
    end

    context "with --write option" do
      it "writes formatted content back to file" do
        Tempfile.create(%w[towrite .ftl]) do |f|
          f.write("hello=Hello\n")
          f.flush

          expect {
            command.call(files: [f.path], write: true, check: false, diff: false, with_junk: false)
          }.not_to output.to_stdout

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
            command.call(files: [f.path], write: false, check: true, diff: false, with_junk: false)
          }.not_to raise_error
        end
      end

      it "raises TidyCheckError when file needs formatting" do
        Tempfile.create(%w[unformatted .ftl]) do |f|
          f.write("hello=Hello\n")
          f.flush

          expect {
            command.call(files: [f.path], write: false, check: true, diff: false, with_junk: false)
          }.to raise_error(Foxtail::CLI::TidyCheckError)
        end
      end
    end

    context "with --diff option" do
      it "shows diff when file needs formatting" do
        Tempfile.create(%w[unformatted .ftl]) do |f|
          f.write("hello=Hello\n")
          f.flush

          output = capture_system_stdout {
            command.call(files: [f.path], write: false, check: false, diff: true, with_junk: false)
          }

          expect(output).to include("-hello=Hello")
          expect(output).to include("+hello = Hello")
        end
      end
    end

    context "with syntax errors (Junk)" do
      it "raises TidyError by default" do
        Tempfile.create(%w[broken .ftl]) do |f|
          f.write("hello = Hi\nbad entry\n")
          f.flush

          expect {
            command.call(files: [f.path], write: false, check: false, diff: false, with_junk: false)
          }.to raise_error(Foxtail::CLI::TidyError)
        end
      end

      it "includes Junk when --with-junk is specified" do
        Tempfile.create(%w[broken .ftl]) do |f|
          f.write("hello = Hi\nbad entry\n")
          f.flush

          expect {
            command.call(files: [f.path], write: false, check: false, diff: false, with_junk: true)
          }.to output(/hello = Hi.*bad entry/m).to_stdout
        end
      end
    end
  end
end
