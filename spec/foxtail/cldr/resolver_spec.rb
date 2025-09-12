# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Resolver do
  let(:temp_dir) { Dir.mktmpdir }
  let(:data_dir) { temp_dir }
  let(:inheritance) { Foxtail::CLDR::Inheritance.instance }

  before do
    allow(inheritance).to receive(:log)
  end

  after { FileUtils.rm_rf(temp_dir) }

  describe "#resolve" do
    before do
      # Create test data files
      create_test_data("root", {
        "number_formats" => {
          "symbols" => {"decimal" => ".", "group" => ","},
          "currencies" => {
            "USD" => {"symbol" => "$", "name" => "US Dollar"},
            "EUR" => {"symbol" => "€", "name" => "Euro"}
          }
        }
      })

      create_test_data("ja", {
        "number_formats" => {
          "symbols" => {"decimal" => ".", "group" => ","},
          "currencies" => {
            "USD" => {"name" => "米ドル"}
          }
        }
      })

      create_test_data("ja_JP", {
        "number_formats" => {
          "currencies" => {
            "JPY" => {"symbol" => "¥", "name" => "円"}
          }
        }
      })
    end

    context "with simple inheritance" do
      let(:resolver) { Foxtail::CLDR::Resolver.new("ja_JP", data_dir:) }

      it "resolves data from current locale" do
        expect(resolver.resolve("number_formats.currencies.JPY.symbol", "number_formats")).to eq("¥")
      end

      it "resolves data from parent locale" do
        expect(resolver.resolve("number_formats.currencies.USD.name", "number_formats")).to eq("米ドル")
      end

      it "resolves data from root locale" do
        expect(resolver.resolve("number_formats.currencies.EUR.symbol", "number_formats")).to eq("€")
      end

      it "returns nil for non-existent data" do
        expect(resolver.resolve("number_formats.currencies.GBP.symbol", "number_formats")).to be_nil
      end

      it "caches resolved values" do
        # Set up spy
        allow(resolver).to receive(:load_locale_data).and_call_original

        # First call loads from file
        resolver.resolve("number_formats.currencies.EUR.symbol", "number_formats")
        expect(resolver).to have_received(:load_locale_data).exactly(3).times

        # Second call uses cache
        resolver.resolve("number_formats.currencies.EUR.symbol", "number_formats")
        expect(resolver).to have_received(:load_locale_data).exactly(3).times # Should still be 3, not more
      end
    end

    context "with nested data resolution" do
      let(:resolver) { Foxtail::CLDR::Resolver.new("ja_JP", data_dir:) }

      it "resolves nested hash structures" do
        expect(resolver.resolve("number_formats.symbols", "number_formats")).to eq({
          "decimal" => ".",
          "group" => ","
        })
      end

      it "handles partial path resolution" do
        expect(resolver.resolve("number_formats.currencies.USD", "number_formats")).to eq({
          "symbol" => "$",
          "name" => "米ドル"
        })
      end
    end

    context "with missing intermediate locales" do
      before do
        # Create only root and ja_JP, skip ja
        FileUtils.rm_rf(File.join(data_dir, "ja"))
      end

      let(:resolver) { Foxtail::CLDR::Resolver.new("ja_JP", data_dir:) }

      it "falls back to root when parent is missing" do
        expect(resolver.resolve("number_formats.currencies.USD.symbol", "number_formats")).to eq("$")
      end
    end

    context "with datetime formats" do
      before do
        create_test_data("root", {
          "datetime_formats" => {
            "date_formats" => {"medium" => "MMM d, y"},
            "months" => {
              "format" => {
                "wide" => {
                  "1" => "January",
                  "2" => "February"
                }
              }
            }
          }
        })

        create_test_data("ja", {
          "datetime_formats" => {
            "months" => {
              "format" => {
                "wide" => {
                  "1" => "1月",
                  "2" => "2月"
                }
              }
            }
          }
        })
      end

      let(:resolver) { Foxtail::CLDR::Resolver.new("ja", data_dir:) }

      it "resolves datetime format data" do
        expect(resolver.resolve("datetime_formats.months.format.wide.1", "datetime_formats")).to eq("1月")
      end

      it "falls back to root for missing datetime data" do
        expect(resolver.resolve("datetime_formats.date_formats.medium", "datetime_formats")).to eq("MMM d, y")
      end
    end
  end

  private def create_test_data(locale, data)
    locale_dir = File.join(data_dir, locale)
    FileUtils.mkdir_p(locale_dir)

    data.each do |data_type, content|
      file_path = File.join(locale_dir, "#{data_type}.yml")
      yaml_content = {
        "locale" => locale,
        "generated_at" => Time.now.utc.iso8601,
        "cldr_version" => "46",
        data_type => content
      }
      File.write(file_path, yaml_content.to_yaml)
    end
  end
end
