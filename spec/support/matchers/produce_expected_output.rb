# frozen_string_literal: true

require "tempfile"

RSpec::Matchers.define :produce_expected_output do |expected_file|
  match do |example_file|
    @example_file = example_file
    @actual = %x(bundle exec ruby #{example_file})
    @expected = expected_file.read
    @actual == @expected
  end

  failure_message do
    diff = generate_diff(@expected, @actual)
    "expected #{@example_file.basename} to produce expected output\n\n#{diff}"
  end

  def generate_diff(expected, actual)
    Tempfile.create("expected") do |exp|
      Tempfile.create("actual") do |act|
        exp.write(expected)
        exp.flush
        act.write(actual)
        act.flush
        %x(diff -u #{exp.path} #{act.path}).sub(/^---.*\n/, "--- expected\n").sub(/^\+\+\+.*\n/, "+++ actual\n")
      end
    end
  end
end
