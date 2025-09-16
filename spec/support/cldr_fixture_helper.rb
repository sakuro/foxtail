# frozen_string_literal: true

module CLDRFixtureHelper
  # Copy CLDR fixture files to a temporary directory structure
  # @param temp_dir [Pathname] Base temporary directory
  # @param files [Array<String>] List of fixture files to copy
  # @return [Pathname] Path to created CLDR source directory
  def setup_cldr_fixture(temp_dir, files)
    # Create CLDR directory structure
    main_dir = temp_dir + "common" + "main"
    supplemental_dir = temp_dir + "common" + "supplemental"

    main_dir.mkpath
    supplemental_dir.mkpath

    # Copy specified fixture files
    fixture_dir = Pathname(__dir__) + ".." + "fixtures" + "cldr"

    files.each do |file|
      source_path = fixture_dir + file
      next unless source_path.exist?

      # Determine destination based on file type
      dest_dir = if file.include?("supplemental") || file == "likelySubtags.xml" || file == "plurals.xml" || file == "metaZones.xml"
                   supplemental_dir
                 else
                   main_dir
                 end

      base_name = Pathname(file).basename(".xml").to_s.sub(/^test_/, "")
      dest_path = dest_dir + "#{base_name}.xml"
      FileUtils.cp(source_path, dest_path)
    end

    temp_dir
  end

  # Convenience method for common fixture sets
  def setup_basic_cldr_fixture(temp_dir)
    setup_cldr_fixture(temp_dir, %w[root.xml en.xml ja.xml supplementalData.xml plurals.xml])
  end

  def setup_locale_aliases_fixture(temp_dir)
    setup_cldr_fixture(temp_dir, %w[supplementalMetadata.xml likelySubtags.xml])
  end

  def setup_inheritance_test_fixture(temp_dir)
    setup_cldr_fixture(temp_dir, %w[test_supplementalData.xml])
  end

  def setup_extractor_test_fixture(temp_dir)
    setup_cldr_fixture(temp_dir, %w[en.xml fr.xml de.xml])
  end

  def setup_malformed_xml_fixture(temp_dir)
    setup_cldr_fixture(temp_dir, %w[malformed_supplementalData.xml])
  end

  def setup_metazone_mapping_fixture(temp_dir)
    setup_cldr_fixture(temp_dir, %w[metaZones.xml])
  end
end
