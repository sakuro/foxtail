# frozen_string_literal: true

require "json"
require "tempfile"

RSpec.describe Foxtail::CLI::Commands::Ids do
  subject(:command) { Foxtail::CLI::Commands::Ids.new }

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
    context "with default options" do
      it "outputs all message and term IDs" do
        Tempfile.create(%w[test .ftl]) do |f|
          f.write(ftl_content)
          f.flush

          expect {
            command.call(files: [f.path], only_messages: false, only_terms: false, with_attributes: false, json: false)
          }.to output("hello\ngreeting\n-brand\n").to_stdout
        end
      end
    end

    context "with --only-messages option" do
      it "outputs only message IDs" do
        Tempfile.create(%w[test .ftl]) do |f|
          f.write(ftl_content)
          f.flush

          expect {
            command.call(files: [f.path], only_messages: true, only_terms: false, with_attributes: false, json: false)
          }.to output("hello\ngreeting\n").to_stdout
        end
      end
    end

    context "with --only-terms option" do
      it "outputs only term IDs" do
        Tempfile.create(%w[test .ftl]) do |f|
          f.write(ftl_content)
          f.flush

          expect {
            command.call(files: [f.path], only_messages: false, only_terms: true, with_attributes: false, json: false)
          }.to output("-brand\n").to_stdout
        end
      end
    end

    context "with --with-attributes option" do
      it "includes attribute names" do
        Tempfile.create(%w[test .ftl]) do |f|
          f.write(ftl_content)
          f.flush

          expect {
            command.call(files: [f.path], only_messages: false, only_terms: false, with_attributes: true, json: false)
          }.to output("hello\ngreeting\ngreeting.placeholder\n-brand\n-brand.short\n").to_stdout
        end
      end
    end

    context "with --json option" do
      it "outputs as JSON array" do
        Tempfile.create(%w[test .ftl]) do |f|
          f.write(ftl_content)
          f.flush

          output = capture_stdout {
            command.call(files: [f.path], only_messages: false, only_terms: false, with_attributes: false, json: true)
          }

          expect(JSON.parse(output)).to eq(%w[hello greeting -brand])
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

          expect {
            command.call(files: [a_path, b_path], only_messages: false, only_terms: false, with_attributes: false, json: false)
          }.to output("msg-a\nmsg-b\n").to_stdout
        end
      end
    end
  end
end
