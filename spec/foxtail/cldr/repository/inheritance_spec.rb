# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Repository::Inheritance do
  let(:inheritance) { Foxtail::CLDR::Repository::Inheritance.instance }

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

  describe "#load_parent_locale_ids" do
    let(:temp_dir) { Pathname(Dir.mktmpdir) }
    let(:parent_locales_file) { temp_dir + "parent_locales.yml" }

    after { FileUtils.rm_rf(temp_dir) }

    it "loads parent locale mappings from YAML data" do
      yaml_content = {
        "parent_locales" => {
          "en_AU" => "en_001",
          "en_CA" => "en_001",
          "en_NZ" => "en_001",
          "es_AR" => "es_419",
          "es_MX" => "es_419"
        }
      }

      parent_locales_file.write(yaml_content.to_yaml)

      parents = inheritance.load_parent_locale_ids(temp_dir)

      expect(parents).to eq({
        "en_AU" => "en_001",
        "en_CA" => "en_001",
        "en_NZ" => "en_001",
        "es_AR" => "es_419",
        "es_MX" => "es_419"
      })
    end

    it "raises ArgumentError when parent locales file does not exist" do
      expect {
        inheritance.load_parent_locale_ids(temp_dir)
      }.to raise_error(ArgumentError, /Parent locales data not found/)
    end

    it "raises ArgumentError when YAML is malformed" do
      parent_locales_file.write("invalid: yaml: [")

      expect {
        inheritance.load_parent_locale_ids(temp_dir)
      }.to raise_error(ArgumentError, /Could not load parent locales/)
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
end
