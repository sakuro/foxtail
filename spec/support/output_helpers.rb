# frozen_string_literal: true

require "stringio"

module OutputHelpers
  # Capture stdout output from a block
  #
  # @yield the block to execute
  # @return [String] the captured stdout
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  # Capture stdout from system calls (e.g., system("diff", ...))
  # Uses file descriptor reopen to capture subprocess output
  #
  # @yield the block to execute
  # @return [String] the captured stdout
  def capture_system_stdout
    Tempfile.create("stdout") do |stdout_capture|
      original_stdout = $stdout.dup
      $stdout.reopen(stdout_capture)

      begin
        yield
      ensure
        $stdout.flush
        $stdout.reopen(original_stdout)
        original_stdout.close
      end

      stdout_capture.rewind
      stdout_capture.read
    end
  end
end

RSpec.configure do |config|
  config.include OutputHelpers
end
