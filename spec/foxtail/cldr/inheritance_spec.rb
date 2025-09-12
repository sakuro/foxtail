# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Inheritance do
  let(:inheritance) { Foxtail::CLDR::Inheritance.instance }

  describe "#resolve_inheritance_chain" do
    it "resolves simple language locale" do
      chain = inheritance.resolve_inheritance_chain("en")
      expect(chain).to eq(%w[en root])
    end

    it "resolves language_Territory locale" do
      chain = inheritance.resolve_inheritance_chain("en_US")
      expect(chain).to eq(%w[en_US en root])
    end

    it "resolves language_Script locale" do
      chain = inheritance.resolve_inheritance_chain("zh_Hans")
      expect(chain).to eq(%w[zh_Hans zh root])
    end

    it "resolves language_Script_Territory locale" do
      chain = inheritance.resolve_inheritance_chain("zh_Hans_CN")
      expect(chain).to eq(%w[zh_Hans_CN zh_Hans zh root])
    end

    it "handles root locale" do
      chain = inheritance.resolve_inheritance_chain("root")
      expect(chain).to eq(["root"])
    end

    it "handles complex locales with three-letter language codes" do
      chain = inheritance.resolve_inheritance_chain("ast_ES")
      expect(chain).to eq(%w[ast_ES ast root])
    end
  end

  describe "#load_parent_locales" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:supplemental_dir) { File.join(temp_dir, "common", "supplemental") }
    let(:supplemental_file) { File.join(supplemental_dir, "supplementalData.xml") }

    before do
      FileUtils.mkdir_p(supplemental_dir)
    end

    after { FileUtils.rm_rf(temp_dir) }

    it "loads parent locale mappings from supplemental data" do
      xml_content = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <supplementalData>
          <parentLocales>
            <parentLocale parent="en_001" locales="en_AU en_CA en_NZ"/>
            <parentLocale parent="es_419" locales="es_AR es_MX"/>
          </parentLocales>
        </supplementalData>
      XML

      File.write(supplemental_file, xml_content)

      parents = inheritance.load_parent_locales(temp_dir)

      expect(parents).to eq({
        "en_AU" => "en_001",
        "en_CA" => "en_001",
        "en_NZ" => "en_001",
        "es_AR" => "es_419",
        "es_MX" => "es_419"
      })
    end

    it "returns empty hash when supplemental file does not exist" do
      parents = inheritance.load_parent_locales(temp_dir)
      expect(parents).to eq({})
    end

    it "handles malformed XML gracefully" do
      File.write(supplemental_file, "invalid xml")

      parents = inheritance.load_parent_locales(temp_dir)
      expect(parents).to eq({})
    end
  end

  describe "#resolve_inheritance_chain_with_parents" do
    let(:parent_locales) do
      {
        "en_AU" => "en_001",
        "en_001" => "en",
        "es_MX" => "es_419"
      }
    end

    it "uses parent locales mappings when available" do
      chain = inheritance.resolve_inheritance_chain_with_parents("en_AU", parent_locales)
      expect(chain).to eq(%w[en_AU en_001 en root])
    end

    it "falls back to algorithmic resolution when no parent mapping exists" do
      chain = inheritance.resolve_inheritance_chain_with_parents("de_DE", parent_locales)
      expect(chain).to eq(%w[de_DE de root])
    end

    it "prevents infinite loops in parent chains" do
      circular_parents = {"a" => "b", "b" => "a"}
      chain = inheritance.resolve_inheritance_chain_with_parents("a", circular_parents)
      expect(chain).to eq(%w[a b root])
    end

    it "handles chain ending in root explicitly" do
      explicit_root = {"en_US" => "en", "en" => "root"}
      chain = inheritance.resolve_inheritance_chain_with_parents("en_US", explicit_root)
      expect(chain).to eq(%w[en_US en root])
    end
  end

  describe "#merge_data" do
    it "merges nested hash structures" do
      parent_data = {
        "numbers" => {
          "symbols" => {"decimal" => ".", "group" => ","},
          "formats" => {"decimal" => "#,##0.###"}
        }
      }

      child_data = {
        "numbers" => {
          "symbols" => {"decimal" => ","},
          "currencies" => {"USD" => {"symbol" => "$"}}
        }
      }

      merged = inheritance.merge_data(parent_data, child_data)

      expect(merged).to eq({
        "numbers" => {
          "symbols" => {"decimal" => ",", "group" => ","},
          "formats" => {"decimal" => "#,##0.###"},
          "currencies" => {"USD" => {"symbol" => "$"}}
        }
      })
    end

    it "allows child data to override parent data" do
      parent_data = {"format" => "parent", "shared" => "parent"}
      child_data = {"format" => "child", "extra" => "child"}

      merged = inheritance.merge_data(parent_data, child_data)

      expect(merged).to eq({
        "format" => "child",
        "shared" => "parent",
        "extra" => "child"
      })
    end

    it "handles nil and empty data" do
      expect(inheritance.merge_data(nil, {"a" => 1})).to eq({"a" => 1})
      expect(inheritance.merge_data({"a" => 1}, nil)).to eq({"a" => 1})
      expect(inheritance.merge_data({}, {"a" => 1})).to eq({"a" => 1})
    end
  end

  describe "#load_inherited_data" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:main_dir) { File.join(temp_dir, "common", "main") }
    let(:extractor) { instance_double(Foxtail::CLDR::Extractors::BaseExtractor) }

    before do
      FileUtils.mkdir_p(main_dir)
    end

    after { FileUtils.rm_rf(temp_dir) }

    it "loads and merges data following inheritance chain" do
      # Create test XML files
      root_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <ldml><numbers><symbols><decimal>.</decimal><group>,</group></symbols></numbers></ldml>
      XML

      en_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <ldml><numbers><symbols><decimal>.</decimal></symbols><currencies><USD><symbol>$</symbol></USD></currencies></numbers></ldml>
      XML

      en_us_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <ldml><numbers><currencies><USD><name>Dollar</name></USD></currencies></numbers></ldml>
      XML

      File.write(File.join(main_dir, "root.xml"), root_xml)
      File.write(File.join(main_dir, "en.xml"), en_xml)
      File.write(File.join(main_dir, "en_US.xml"), en_us_xml)

      # Mock extractor responses
      allow(extractor).to receive(:extract_data_from_xml) do |doc|
        if doc.to_s.include?("group")
          {"symbols" => {"decimal" => ".", "group" => ","}}
        elsif doc.to_s.include?("Dollar")
          {"currencies" => {"USD" => {"name" => "Dollar"}}}
        else
          {"symbols" => {"decimal" => "."}, "currencies" => {"USD" => {"symbol" => "$"}}}
        end
      end

      merged_data = inheritance.load_inherited_data("en_US", temp_dir, extractor)

      expected = {
        "symbols" => {"decimal" => ".", "group" => ","},
        "currencies" => {"USD" => {"symbol" => "$", "name" => "Dollar"}}
      }

      expect(merged_data).to eq(expected)
    end

    it "handles missing locale files gracefully" do
      allow(extractor).to receive(:extract_data_from_xml).and_return({"test" => "data"})

      File.write(File.join(main_dir, "root.xml"), "<ldml></ldml>")

      merged_data = inheritance.load_inherited_data("missing_US", temp_dir, extractor)

      expect(merged_data).to eq({"test" => "data"})
    end
  end
end
