# frozen_string_literal: true

require_relative "base_extractor"

module Foxtail
  module CLDR
    module Extractors
      # Extracts date and time format data from CLDR XML and writes to YAML files
      class DateTimeFormatsExtractor < BaseExtractor
        CALENDAR_CONTEXTS = %w[format stand-alone].freeze
        private_constant :CALENDAR_CONTEXTS

        MONTH_DAY_WIDTHS = %w[wide abbreviated narrow].freeze
        private_constant :MONTH_DAY_WIDTHS

        QUARTER_DAY_PERIOD_WIDTHS = %w[wide abbreviated].freeze
        private_constant :QUARTER_DAY_PERIOD_WIDTHS
        private def data_type_name
          "datetime formats"
        end

        private def extract_data_from_xml(xml_doc)
          {
            "calendars" => extract_calendars(xml_doc),
            "date_formats" => extract_date_formats(xml_doc),
            "time_formats" => extract_time_formats(xml_doc),
            "datetime_formats" => extract_datetime_formats(xml_doc)
          }
        end

        private def extract_calendars(xml_doc)
          calendars = {}

          # Focus on Gregorian calendar
          xml_doc.elements.each("ldml/dates/calendars/calendar[@type='gregorian']") do |calendar|
            calendars["gregorian"] = {
              "months" => extract_months(calendar),
              "days" => extract_days(calendar),
              "quarters" => extract_quarters(calendar),
              "day_periods" => extract_day_periods(calendar),
              "eras" => extract_eras(calendar)
            }
          end

          calendars
        end

        # Extract month names
        private def extract_months(calendar_element)
          months = {
            "format" => {"wide" => {}, "abbreviated" => {}, "narrow" => {}},
            "stand_alone" => {"wide" => {}, "abbreviated" => {}, "narrow" => {}}
          }

          CALENDAR_CONTEXTS.each do |context|
            MONTH_DAY_WIDTHS.each do |width|
              calendar_element.elements.each("months/monthContext[@type='#{context}']/monthWidth[@type='#{width}']/month") do |month|
                type = month.attributes["type"]
                next unless type

                context_key = context.tr("-", "_")
                months[context_key][width][Integer(type, 10)] = month.text
              end
            end
          end

          months
        end

        # Extract day names
        private def extract_days(calendar_element)
          days = {
            "format" => {"wide" => {}, "abbreviated" => {}, "narrow" => {}},
            "stand_alone" => {"wide" => {}, "abbreviated" => {}, "narrow" => {}}
          }

          CALENDAR_CONTEXTS.each do |context|
            MONTH_DAY_WIDTHS.each do |width|
              calendar_element.elements.each("days/dayContext[@type='#{context}']/dayWidth[@type='#{width}']/day") do |day|
                type = day.attributes["type"]
                next unless type

                context_key = context.tr("-", "_")
                days[context_key][width][type] = day.text
              end
            end
          end

          days
        end

        # Extract quarter names
        private def extract_quarters(calendar_element)
          quarters = {
            "format" => {"wide" => {}, "abbreviated" => {}},
            "stand_alone" => {"wide" => {}, "abbreviated" => {}}
          }

          CALENDAR_CONTEXTS.each do |context|
            QUARTER_DAY_PERIOD_WIDTHS.each do |width|
              calendar_element.elements.each("quarters/quarterContext[@type='#{context}']/quarterWidth[@type='#{width}']/quarter") do |quarter|
                type = quarter.attributes["type"]
                next unless type

                context_key = context.tr("-", "_")
                quarters[context_key][width][Integer(type, 10)] = quarter.text
              end
            end
          end

          quarters
        end

        # Extract day period names (AM/PM, etc.)
        private def extract_day_periods(calendar_element)
          periods = {
            "format" => {"wide" => {}, "abbreviated" => {}},
            "stand_alone" => {"wide" => {}, "abbreviated" => {}}
          }

          CALENDAR_CONTEXTS.each do |context|
            QUARTER_DAY_PERIOD_WIDTHS.each do |width|
              calendar_element.elements.each("dayPeriods/dayPeriodContext[@type='#{context}']/dayPeriodWidth[@type='#{width}']/dayPeriod") do |period|
                type = period.attributes["type"]
                next unless type

                context_key = context.tr("-", "_")
                periods[context_key][width][type] = period.text
              end
            end
          end

          periods
        end

        # Extract era names
        private def extract_eras(calendar_element)
          eras = {
            "names" => {},
            "abbreviated" => {},
            "narrow" => {}
          }

          calendar_element.elements.each("eras/eraNames/era") do |era|
            type = era.attributes["type"]
            eras["names"][Integer(type, 10)] = era.text if type
          end

          calendar_element.elements.each("eras/eraAbbr/era") do |era|
            type = era.attributes["type"]
            eras["abbreviated"][Integer(type, 10)] = era.text if type
          end

          calendar_element.elements.each("eras/eraNarrow/era") do |era|
            type = era.attributes["type"]
            eras["narrow"][Integer(type, 10)] = era.text if type
          end

          eras
        end

        # Extract date format patterns
        private def extract_date_formats(xml_doc)
          formats = {}

          xml_doc.elements.each("ldml/dates/calendars/calendar[@type='gregorian']/dateFormats/dateFormatLength") do |format_length|
            length = format_length.attributes["type"]
            next unless length

            format_length.elements.each("dateFormat/pattern") do |pattern|
              formats[length] = pattern.text
            end
          end

          formats
        end

        # Extract time format patterns
        private def extract_time_formats(xml_doc)
          formats = {}

          xml_doc.elements.each("ldml/dates/calendars/calendar[@type='gregorian']/timeFormats/timeFormatLength") do |format_length|
            length = format_length.attributes["type"]
            next unless length

            format_length.elements.each("timeFormat/pattern") do |pattern|
              formats[length] = pattern.text
            end
          end

          formats
        end

        # Extract combined datetime format patterns
        private def extract_datetime_formats(xml_doc)
          formats = {}

          xml_doc.elements.each("ldml/dates/calendars/calendar[@type='gregorian']/dateTimeFormats/dateTimeFormatLength") do |format_length|
            length = format_length.attributes["type"]
            next unless length

            format_length.elements.each("dateTimeFormat/pattern") do |pattern|
              formats[length] = pattern.text
            end
          end

          # Also extract available formats (additional patterns)
          available_formats = {}
          xml_doc.elements.each("ldml/dates/calendars/calendar[@type='gregorian']/dateTimeFormats/availableFormats/dateFormatItem") do |item|
            id = item.attributes["id"]
            available_formats[id] = item.text if id
          end

          formats["available_formats"] = available_formats unless available_formats.empty?

          formats
        end

        private def data?(data)
          return false unless data.is_a?(Hash)

          data.any? {|_, section_data| section_data.is_a?(Hash) && !section_data.empty? }
        end

        private def write_data(locale_id, data)
          write_yaml_file(locale_id, "datetime_formats.yml", data)
        end
      end
    end
  end
end
