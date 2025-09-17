# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Foxtail::CLDR::Repository::Resolver do
  let(:temp_dir) { Pathname(Dir.mktmpdir) }
  let(:data_dir) { temp_dir }
  let(:inheritance) { Foxtail::CLDR::Repository::Inheritance.instance }

  after { FileUtils.rm_rf(temp_dir) }

  describe "#resolve" do
    context "with simple inheritance" do
      before do
        # Copy fixture files to test data directory
        copy_fixture_data(%w[root ja ja_JP], "number_formats")
      end

      let(:resolver) { Foxtail::CLDR::Repository::Resolver.new("ja_JP", data_dir:) }

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
      before do
        copy_fixture_data(%w[root ja ja_JP], "number_formats")
      end

      let(:resolver) { Foxtail::CLDR::Repository::Resolver.new("ja_JP", data_dir:) }

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
        copy_fixture_data(%w[root ja_JP], "number_formats")
      end

      let(:resolver) { Foxtail::CLDR::Repository::Resolver.new("ja_JP", data_dir:) }

      it "falls back to root when parent is missing" do
        expect(resolver.resolve("number_formats.currencies.USD.symbol", "number_formats")).to eq("$")
      end
    end

    context "with datetime formats" do
      before do
        copy_fixture_data(%w[root ja], "datetime_formats")
      end

      let(:resolver) { Foxtail::CLDR::Repository::Resolver.new("ja", data_dir:) }

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
        data_dir = Foxtail.cldr_dir

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
        data_dir = Foxtail.cldr_dir
        aliases = inheritance.load_locale_aliases(data_dir)

        # Test with simple compound case that works with current implementation
        canonical = inheritance.resolve_locale_alias("in_BU", aliases)
        expect(canonical).to eq("id_MM")

        # NOTE: More complex cases like "no_bok_BU" don't work perfectly because
        # the current implementation splits on all underscores, treating "no_bok_BU"
        # as ["no", "bok", "BU"] instead of ["no_bok", "BU"]
      end

      it "returns original locale if no alias exists" do
        data_dir = Foxtail.cldr_dir
        aliases = inheritance.load_locale_aliases(data_dir)

        canonical = inheritance.resolve_locale_alias("en_US", aliases)
        expect(canonical).to eq("en_US")
      end
    end

    context "with parent locales data" do
      before do
        # Copy parent locales fixture
        fixtures_dir = Pathname(__dir__).parent.parent.parent + "fixtures" + "cldr"
        FileUtils.cp(fixtures_dir + "test_parent_locales.yml", data_dir + "parent_locales.yml")

        # Copy fixture data for inheritance chain testing
        copy_fixture_data(%w[root en en_001], "number_formats")
      end

      let(:resolver) { Foxtail::CLDR::Repository::Resolver.new("en_AU", data_dir:) }

      it "uses parent locales for inheritance chain resolution" do
        # Should resolve with chain: en_AU -> en_001 -> en -> root
        result = resolver.resolve("number_formats.currencies.USD", "number_formats")

        # Should get symbol from en_001 and name from en
        expect(result).to eq({
          "symbol" => "US$", # from en_001
          "name" => "US Dollar" # from en
        })
      end

      it "falls back to algorithmic inheritance when parent locales file is missing" do
        # Remove parent locales file
        (data_dir + "parent_locales.yml").delete

        resolver_without_parents = Foxtail::CLDR::Repository::Resolver.new("en_AU", data_dir:)

        # Should resolve with algorithmic chain: en_AU -> en -> root
        # (en_001 would be skipped)
        result = resolver_without_parents.resolve("number_formats.currencies.USD", "number_formats")

        # Should get name from en and symbol from root (en_001 would be skipped)
        expect(result).to eq({
          "name" => "US Dollar", # from en
          "symbol" => "$" # from root
        })
      end
    end
  end

  private def copy_fixture_data(locales, data_type)
    fixtures_dir = Pathname(__dir__).parent.parent.parent + "fixtures" + "cldr"

    locales.each do |locale|
      source_file = fixtures_dir + locale + "#{data_type}.yml"

      locale_dir = data_dir + locale
      locale_dir.mkpath
      dest_file = locale_dir + "#{data_type}.yml"
      FileUtils.cp(source_file, dest_file)
    end
  end
end
