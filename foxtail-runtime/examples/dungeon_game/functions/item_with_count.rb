# frozen_string_literal: true

# Value types for ItemFunctions that defer formatting until display time.
# These inherit from Foxtail::Function::Value to integrate with the resolver.
module ItemFunctions
  # Value type for ITEM_WITH_COUNT function - wraps item_id and count with formatting options.
  # value is [item_id, count] array
  class ItemWithCount < Foxtail::Function::Value
    # Format the item with count for display
    # @param bundle [Foxtail::Bundle] the bundle providing locale context
    # @return [String] the formatted item name with count
    def format(bundle:) = ItemFunctions.handler_for(bundle).format_item_with_count(*value, bundle:, **options)
  end
end
