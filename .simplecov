# frozen_string_literal: true

SimpleCov.start do
  # Add coverage filter for non-production code
  add_filter "/spec/"
  add_filter "/vendor/"
  add_filter "/examples/"

  # Track these directories
  add_group "Library", "lib"

  # Coverage thresholds - restored and improved beyond original target
  minimum_coverage 90.0 # Achieved: 96.99% line coverage, 90.73% branch coverage
  # minimum_coverage_by_file 80  # Could be enabled with current high coverage

  # Enable branch coverage (Ruby 2.5+)
  enable_coverage :branch if respond_to?(:enable_coverage)

  # Coverage formats
  formatter SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter, # HTML report in coverage/
      SimpleCov::Formatter::SimpleFormatter # Console output
    ]
  )

  # Merge multiple test runs (useful for parallel testing)
  merge_timeout 3600
end
