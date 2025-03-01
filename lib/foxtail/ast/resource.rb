# frozen_string_literal: true

module Foxtail
  module AST
    # Represents a complete FTL resource
    class Resource < Node
      attr_reader :entries
      attr_accessor :resource_id

      def initialize(entries=[])
        @entries = entries
        @resource_id = nil
        @entry_map = {}
        index_entries
      end

      def entries=(entries)
        @entries = entries
        @entry_map = {}
        index_entries
      end

      def get_message(id)
        @entry_map[id]
      end

      private

      def index_entries
        @entries.each do |entry|
          next unless entry.is_a?(Message) || entry.is_a?(Term)

          @entry_map[entry.id] = entry
        end
      end
    end
  end
end
