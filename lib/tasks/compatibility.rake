# frozen_string_literal: true

require_relative "../../compat/fluent_js/compatibility_reporter"
require_relative "../../compat/fluent_js/compatibility_tester"
require_relative "../../compat/node_intl/reporter"
require_relative "../../compat/node_intl/tester"
require_relative "../foxtail"

# Helper method to check environment requirements for compatibility tests
def check_compatibility_test_environment!
  required_ruby_major_minor = "3.4"
  optimal_timezone = "UTC+0"

  # Check Ruby version (major.minor)
  current_ruby_major_minor = RUBY_VERSION.split(".")[0..1].join(".")
  if current_ruby_major_minor != required_ruby_major_minor
    warning_message = <<~WARNING
      ⚠️  WARNING: Ruby version mismatch
         Current: Ruby #{RUBY_VERSION}
         Required: Ruby #{required_ruby_major_minor}.x

         For consistent results with CI, please run with Ruby #{required_ruby_major_minor}.x:
         mise exec ruby@#{required_ruby_major_minor} -- rake compatibility:node_intl

         Or if you use rbenv/rvm:
         rbenv local #{required_ruby_major_minor}.x && rake compatibility:node_intl

    WARNING
    puts warning_message
    exit 1
  end

  # Check timezone
  current_tz = ENV.fetch("TZ", nil)
  if current_tz != optimal_timezone
    detected_timezone = Time.now.zone
    detected_offset = Time.now.utc_offset

    # Allow other UTC formats with a note
    if current_tz&.match?(/^(UTC|UTC[+-]0(:[0-5]\d)?|GMT|GMT[+-]0(:[0-5]\d)?)$/) || (current_tz.nil? && detected_offset == 0)
      note_message = <<~NOTE
        ℹ️  Note: Timezone configuration
           Current: TZ=#{current_tz.inspect} (detected: #{detected_timezone}, offset: #{detected_offset})
           Optimal: TZ=UTC+0 (for exact CI match with 30 DateTimeFormat mismatches)

           Your current configuration may work, but for exact CI compatibility use:
           mise exec ruby@#{required_ruby_major_minor} -- env TZ=UTC+0 rake compatibility:node_intl

      NOTE
      puts note_message
    else
      timezone_warning = <<~WARNING
        ⚠️  WARNING: Timezone environment mismatch
           Current: TZ=#{current_tz.inspect} (detected: #{detected_timezone}, offset: #{detected_offset})
           Required: TZ should be UTC+0 for exact CI compatibility (30 mismatches)

           For consistent results with CI, please run with TZ=UTC+0:
           TZ=UTC+0 rake compatibility:node_intl

           Or with mise:
           mise exec ruby@#{required_ruby_major_minor} -- env TZ=UTC+0 rake compatibility:node_intl

           Alternative UTC formats will work but may show different mismatch counts:
           - TZ=UTC: 65 DateTimeFormat mismatches
           - TZ=GMT: 50 DateTimeFormat mismatches

      WARNING
      puts timezone_warning
      exit 1
    end
  end

  success_message = <<~SUCCESS
    ✅ Environment check passed:
       Ruby: #{RUBY_VERSION}
       TZ: #{current_tz} (Time.zone: #{Time.now.zone})
       Expected DateTimeFormat mismatches: 30 (matching CI)

  SUCCESS
  puts success_message
end

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

  desc "Generate Node.js Intl compatibility report (NumberFormat + DateTimeFormat)"
  task :node_intl do
    # Check environment requirements
    check_compatibility_test_environment!

    # Initialize tester and run all tests
    tester = NodeIntlTester.new
    results = tester.test_all

    # Generate report
    reporter = NodeIntlReporter.new(results)

    # Generate and save markdown report
    markdown_report = reporter.generate_markdown_report
    Pathname("compat/node_intl_compatibility_report.md").write(markdown_report)

    # Show summary and file info
    summary = reporter.generate_summary_report
    puts summary
    puts "📄 Detailed report saved to compat/node_intl_compatibility_report.md"
  end
end
