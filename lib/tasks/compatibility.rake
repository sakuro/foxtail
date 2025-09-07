# frozen_string_literal: true

require_relative "../../compat/compatibility_reporter"
require_relative "../../compat/compatibility_tester"
require_relative "../foxtail"

namespace :compatibility do
  desc "Generate fluent.js compatibility report"
  task :report do
    # Initialize tester and run all tests
    tester = CompatibilityTester.new
    results = tester.test_all_fixtures

    # Generate report
    reporter = CompatibilityReporter.new(results)

    # Generate and save markdown report
    markdown_report = reporter.generate_markdown_report
    File.write("compatibility_report.md", markdown_report)

    # Show summary and file info
    summary = reporter.generate_summary_report
    puts summary
    puts "📄 Detailed report saved to compatibility_report.md"
  end
end
