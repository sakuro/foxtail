# frozen_string_literal: true

# Value types for ItemFunctions that defer formatting until display time.
# These inherit from Foxtail::Function::Value to integrate with the resolver.
module ItemFunctions
  # Value type for ITEM function - wraps item_id with formatting options.
  class Item < Foxtail::Function::Value
    # Format the item for display
    # @param bundle [Foxtail::Bundle] the bundle providing locale context
    # @return [String] the formatted item name with article
    def format(bundle:) = Handler.for_bundle(bundle).format_item(value, **options)
  end
end
