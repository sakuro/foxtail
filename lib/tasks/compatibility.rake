# frozen_string_literal: true

require_relative "../../compat/fluent_js/compatibility_reporter"
require_relative "../../compat/fluent_js/compatibility_tester"
require_relative "../foxtail"

namespace :compatibility do
  desc "Generate fluent.js compatibility report"
  task :fluentjs do
    # Initialize tester and run all tests
    tester = CompatibilityTester.new
    results = tester.test_all_fixtures

    # Generate report
    reporter = CompatibilityReporter.new(results)

    # Generate and save markdown report
    markdown_report = reporter.generate_markdown_report
    Pathname("compat/fluentjs_compatibility_report.md").write(markdown_report)

    # Show summary and file info
    summary = reporter.generate_summary_report
    puts summary
    puts "📄 Detailed report saved to compat/fluentjs_compatibility_report.md"
  end
end
