# frozen_string_literal: true

require "locale"

module Foxtail
  module CLDR
    module Repository
      # CLDR datetime formatting data loader and processor
      #
      # Provides locale-specific date and time formatting information including
      # date and time patterns, month names, and weekday names with support
      # for various formatting widths and contexts.
      #
      # @example
      #   formats = DateTimeFormats.new("en")
      #   formats.month_name(1, "wide")     # => "January"
      #   formats.weekday_name("sun", "abbreviated")  # => "Sun"
      #   formats.date_pattern("medium")    # => "MMM d, y"
      #
      # @see https://unicode.org/reports/tr35/tr35-dates.html
      class DateTimeFormats < Base
        # Get month name (1-12)
        def month_name(month, width="wide", context="format")
          months = @resolver.resolve("datetime_formats.months.#{context}.#{width}", "datetime_formats")
          return month.to_s unless months

          months[month.to_s] || month.to_s
        end

        # Get weekday name (sun, mon, tue, wed, thu, fri, sat)
        def weekday_name(day, width="wide", context="format")
          days = @resolver.resolve("datetime_formats.days.#{context}.#{width}", "datetime_formats")
          return day.to_s unless days

          days[day.to_s] || day.to_s
        end

        # Get day period (AM/PM) based on hour (0-23)
        def day_period(hour, width="abbreviated", context="format")
          # Determine AM/PM based on hour
          period_type = hour < 12 ? "am" : "pm"

          day_periods = @resolver.resolve("datetime_formats.day_periods.#{context}.#{width}", "datetime_formats")
          return period_type.upcase unless day_periods

          day_periods[period_type] || period_type.upcase
        end

        # Get date format pattern
        def date_pattern(style="medium")
          @resolver.resolve("datetime_formats.date_formats.#{style}", "datetime_formats") || default_date_pattern(style)
        end

        # Get time format pattern
        def time_pattern(style="medium")
          @resolver.resolve("datetime_formats.time_formats.#{style}", "datetime_formats") || default_time_pattern(style)
        end

        # Get available format pattern for specific field combination
        def available_format(pattern_key)
          @resolver.resolve("datetime_formats.datetime_formats.available_formats.#{pattern_key}", "datetime_formats")
        end

        # Get datetime format pattern (combination)
        def datetime_pattern(date_style="medium", time_style="medium")
          # Get the appropriate combination pattern based on date style
          # CLDR specification: determine combining pattern from date style complexity
          combination_style = determine_combination_style(date_style)
          combination_pattern = @resolver.resolve("datetime_formats.datetime_formats.#{combination_style}", "datetime_formats")

          date_fmt = date_pattern(date_style)
          time_fmt = time_pattern(time_style)
          if combination_pattern
            # Apply CLDR pattern: \{1} = date, \{0} = time
            combination_pattern.gsub(Regexp.union(["{0}", "{1}"]), "{1}" => date_fmt, "{0}" => time_fmt)
          else
            # Fallback to simple concatenation
            "#{date_fmt} #{time_fmt}"
          end
        end

        # Determine combination style based on date style complexity
        # Following CLDR specification for dateTimeFormat selection
        private def determine_combination_style(date_style)
          case date_style
          when "full"
            "full"   # Use full combining pattern for full date
          when "long"
            "long"   # Use long combining pattern for long date
          when "medium"
            "medium" # Use medium combining pattern for medium date
          when "short"
            "short"  # Use short combining pattern for short date
          else
            "medium" # Default fallback
          end
        end

        private def default_date_pattern(style)
          case style
          when "full"   then "EEEE, MMMM d, y"
          when "long"   then "MMMM d, y"
          when "medium" then "MMM d, y"
          when "short"  then "M/d/yy"
          else "MMM d, y"
          end
        end

        # Default time patterns when CLDR data unavailable
        private def default_time_pattern(style)
          case style
          when "full"   then "h:mm:ss a zzzz"
          when "long"   then "h:mm:ss a z"
          when "medium" then "h:mm:ss a"
          when "short"  then "h:mm a"
          else "h:mm:ss a"
          end
        end
      end
    end
  end
end
