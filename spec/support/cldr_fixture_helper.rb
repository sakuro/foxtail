# frozen_string_literal: true

module CLDRFixtureHelper
  # Copy CLDR fixture files to a temporary directory structure
  # @param temp_dir [String] Base temporary directory
  # @param files [Array<String>] List of fixture files to copy
  # @return [String] Path to created CLDR source directory
  def setup_cldr_fixture(temp_dir, files)
    # Create CLDR directory structure
    main_dir = File.join(temp_dir, "common", "main")
    supplemental_dir = File.join(temp_dir, "common", "supplemental")

    FileUtils.mkdir_p(main_dir)
    FileUtils.mkdir_p(supplemental_dir)

    # Copy specified fixture files
    fixture_dir = File.join(__dir__, "..", "fixtures", "cldr")

    files.each do |file|
      source_path = File.join(fixture_dir, file)
      next unless File.exist?(source_path)

      # Determine destination based on file type
      dest_dir = if file.include?("supplemental") || file == "likelySubtags.xml" || file == "plurals.xml"
                   supplemental_dir
                 else
                   main_dir
                 end

      dest_path = File.join(dest_dir, File.basename(file, ".xml").sub(/^test_/, "") + ".xml")
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
end
