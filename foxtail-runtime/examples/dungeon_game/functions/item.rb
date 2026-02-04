# frozen_string_literal: true

# Value types for ItemFunctions that defer formatting until display time.
# These inherit from Foxtail::Function::Value to integrate with the resolver.
module ItemFunctions
  # Value type for ITEM function - wraps item_id with formatting options.
  class Item < Foxtail::Function::Value
    attr_reader :handler

    # @param handler [ItemFunctions::Handler] the locale-specific handler
    # @param item_id [String] the item term reference (e.g., "-sword")
    # @param options [Hash] formatting options (type:, case:, cap:, etc.)
    def initialize(handler, item_id, **)
      super(item_id, **)
      @handler = handler
    end

    # Format the item for display
    # @param bundle [Foxtail::Bundle] the bundle providing locale context
    # @return [String] the formatted item name with article
    def format(bundle:)
      @handler.format_item(value, bundle:, **@options)
    end
  end
end
