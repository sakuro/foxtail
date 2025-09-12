# frozen_string_literal: true

SimpleCov.start do
  # Add coverage filter for non-production code
  add_filter "/spec/"
  add_filter "/vendor/"
  add_filter "/examples/"

  # Track these directories with specific patterns
  add_group "Foxtail" do |src_file|
    src_file.filename.include?("lib/foxtail") && !src_file.filename.include?("lib/foxtail/cldr")
  end
  add_group "CLDR" do |src_file|
    src_file.filename.include?("lib/foxtail/cldr") || src_file.filename.end_with?("lib/foxtail/cldr.rb")
  end

  # Coverage thresholds - set to current baseline levels
  minimum_coverage 80.0 # Current: 84.51% line coverage, 58.36% branch coverage
  # minimum_coverage_by_file 70  # Could be enabled to ensure individual file quality

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
