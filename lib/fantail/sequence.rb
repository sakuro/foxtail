# frozen_string_literal: true

module Fantail
  # Manages ordered sequences of Bundles for language fallback.
  #
  # @example Basic usage
  #   sequence = Fantail::Sequence.new(bundle_en_us, bundle_en, bundle_default)
  #   sequence.format("hello", name: "World")
  #
  # @example Finding the bundle that contains a message
  #   bundle = sequence.find("hello")
  #   puts "Using locale: #{bundle.locale}" if bundle
  #
  # @see https://projectfluent.org/fluent.js/sequence/
  class Sequence
    # Creates a new Sequence with the given bundles.
    #
    # @param bundles [Array<Bundle>] Bundles in priority order (first = highest priority)
    def initialize(*bundles)
      @bundles = bundles.flatten.freeze
    end

    # Finds the first bundle that contains a message with the given ID(s).
    #
    # @param ids [Array<String>] One or more message IDs to find
    # @return [Bundle, nil] The first bundle containing the message (single ID)
    # @return [Array<Bundle, nil>] Array of bundles for each ID (multiple IDs)
    def find(*ids)
      if ids.size == 1
        find_bundle(ids.first)
      else
        ids.map {|id| find_bundle(id) }
      end
    end

    # Formats a message using the first bundle that contains it.
    # Keyword arguments are passed through to the bundle's format method.
    #
    # @param id [String] The message ID
    # @param errors [Array, nil] If provided, errors are collected into this array instead of being ignored.
    # @return [String] The formatted message, or the ID if not found
    def format(id, errors=nil, **)
      bundle = find_bundle(id)
      bundle ? bundle.format(id, errors, **) : id.to_s
    end

    private def find_bundle(id) = @bundles.find {|bundle| bundle.message?(id) }
  end
end
