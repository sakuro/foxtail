# frozen_string_literal: true

# Value types for ItemFunctions that defer formatting until display time.
# These inherit from Foxtail::Function::Value to integrate with the resolver.
module ItemFunctions
  # Value type for ITEM_WITH_COUNT function - wraps item_id and count with formatting options.
  class ItemWithCount < Foxtail::Function::Value
    attr_reader :handler

    # @param handler [ItemFunctions::Handler] the locale-specific handler
    # @param item_id [String] the item term reference (e.g., "-sword")
    # @param count [Integer] the quantity of items
    # @param options [Hash] formatting options (type:, case:, cap:, etc.)
    def initialize(handler, item_id, count, **)
      super([item_id, count], **)
      @handler = handler
    end

    # Format the item with count for display
    # @param bundle [Foxtail::Bundle] the bundle providing locale context
    # @return [String] the formatted item name with count
    def format(bundle:)
      @handler.format_item_with_count(*value, bundle:, **@options)
    end
  end
end
