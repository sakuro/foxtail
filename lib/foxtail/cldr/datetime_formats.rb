# frozen_string_literal: true

require "locale"
require_relative "base"
require_relative "resolver"

module Foxtail
  module CLDR
    # CLDR datetime formatting data loader and processor
    # Provides locale-specific date and time formatting information
    #
    # Based on Unicode CLDR specifications:
    # - https://unicode.org/reports/tr35/tr35-dates.html
    # - Supports date/time patterns, month names, weekday names
    #
    # Example usage:
    #   formats = DateTimeFormats.new("en")
    #   formats.month_name(1, "wide")     # => "January"
    #   formats.weekday_name("sun", "abbreviated")  # => "Sun"
    #   formats.date_pattern("medium")    # => "MMM d, y"
    class DateTimeFormats < Base
      def initialize(locale)
        super
        @resolver = Resolver.new(@locale.to_simple.to_s)
      end

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

      # Get date format pattern
      def date_pattern(style="medium")
        @resolver.resolve("datetime_formats.date_formats.#{style}", "datetime_formats") || default_date_pattern(style)
      end

      # Get time format pattern
      def time_pattern(style="medium")
        @resolver.resolve("datetime_formats.time_formats.#{style}", "datetime_formats") || default_time_pattern(style)
      end

      # Get datetime format pattern (combination)
      def datetime_pattern(date_style="medium", time_style="medium")
        date_fmt = date_pattern(date_style)
        time_fmt = time_pattern(time_style)
        "#{date_fmt} #{time_fmt}"
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
