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
end
