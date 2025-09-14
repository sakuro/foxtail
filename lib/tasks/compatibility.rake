# frozen_string_literal: true

require_relative "../../compat/fluent_js/compatibility_reporter"
require_relative "../../compat/fluent_js/compatibility_tester"
require_relative "../../compat/node_intl/reporter"
require_relative "../../compat/node_intl/tester"
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
    File.write("fluentjs_compatibility_report.md", markdown_report)

    # Show summary and file info
    summary = reporter.generate_summary_report
    puts summary
    puts "📄 Detailed report saved to fluentjs_compatibility_report.md"
  end

  desc "Generate Node.js Intl compatibility report (NumberFormat + DateTimeFormat)"
  task :node_intl do
    # Initialize tester and run all tests
    tester = NodeIntlTester.new
    results = tester.test_all

    # Generate report
    reporter = NodeIntlReporter.new(results)

    # Generate and save markdown report
    markdown_report = reporter.generate_markdown_report
    File.write("node_intl_compatibility_report.md", markdown_report)

    # Show summary and file info
    summary = reporter.generate_summary_report
    puts summary
    puts "📄 Detailed report saved to node_intl_compatibility_report.md"
  end
end
