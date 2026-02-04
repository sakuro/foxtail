# frozen_string_literal: true

RSpec.describe "Examples" do
  examples_dir = Pathname.new(__dir__).join("..", "examples")

  context "with standalone scripts" do
    examples_dir.glob("*.rb").sort.each do |example|
      expected_file = example.sub_ext(".expected.txt")
      next unless expected_file.exist?

      it example.basename(".rb").to_s do
        expect(example).to produce_expected_output(example.sub_ext(".expected.txt"))
      end
    end
  end

  context "with subdirectory apps" do
    examples_dir.glob("*/main.rb").sort.each do |example|
      expected_file = example.dirname.join("expected.txt")
      next unless expected_file.exist?

      it example.dirname.basename.to_s do |ex|
        # TODO: dungeon_game uses custom functions with locale: parameter (see issue #165)
        pending "custom function API change" if ex.description == "dungeon_game"
        expect(example).to produce_expected_output(example.dirname.join("expected.txt"))
      end
    end
  end
end
