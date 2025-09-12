# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Resolver do
  let(:temp_dir) { Dir.mktmpdir }
  let(:data_dir) { temp_dir }
  let(:inheritance) { Foxtail::CLDR::Inheritance.instance }

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

    context "with locale aliases" do
      it "resolves locale aliases including zh_TW to zh_Hant_TW" do
        # Use the real data/cldr directory for testing
        data_dir = File.join(__dir__, "..", "..", "..", "data", "cldr")

        # First test that alias loading works
        aliases = inheritance.load_locale_aliases(data_dir)

        expect(aliases).to include("zh_TW" => "zh_Hant_TW")
        expect(aliases).to include("no_bok" => "nb")
        expect(aliases).to include("in" => "id")
        expect(aliases).to include("BU" => "MM")

        # Test that alias resolution works for zh_TW
        canonical = inheritance.resolve_locale_alias("zh_TW", aliases)
        expect(canonical).to eq("zh_Hant_TW")

        # Test other deprecated codes
        canonical_nb = inheritance.resolve_locale_alias("no_bok", aliases)
        expect(canonical_nb).to eq("nb")

        canonical_id = inheritance.resolve_locale_alias("in", aliases)
        expect(canonical_id).to eq("id")
      end

      it "handles territory aliases in compound locales" do
        data_dir = File.join(__dir__, "..", "..", "..", "data", "cldr")
        aliases = inheritance.load_locale_aliases(data_dir)

        # Test with simple compound case that works with current implementation
        canonical = inheritance.resolve_locale_alias("in_BU", aliases)
        expect(canonical).to eq("id_MM")

        # NOTE: More complex cases like "no_bok_BU" don't work perfectly because
        # the current implementation splits on all underscores, treating "no_bok_BU"
        # as ["no", "bok", "BU"] instead of ["no_bok", "BU"]
      end

      it "returns original locale if no alias exists" do
        data_dir = File.join(__dir__, "..", "..", "..", "data", "cldr")
        aliases = inheritance.load_locale_aliases(data_dir)

        canonical = inheritance.resolve_locale_alias("en_US", aliases)
        expect(canonical).to eq("en_US")
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
