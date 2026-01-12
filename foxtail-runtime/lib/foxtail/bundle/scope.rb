# frozen_string_literal: true

module Foxtail
  class Bundle
    # Variable scope and state management during resolution
    # Corresponds to fluent-bundle/src/scope.ts
    class Scope
      attr_reader :bundle
      attr_reader :args
      attr_reader :locals
      attr_reader :errors
      attr_reader :dirty

      def initialize(bundle, **args)
        @bundle = bundle
        @args = args      # External variables passed to format()
        @locals = {}      # Local variables (set within functions)
        @errors = []      # Error collection during resolution
        @dirty = Set.new  # Circular reference detection (message/term IDs)
      end

      # Get a variable value (checks locals first, then args)
      def variable(name) = @locals[name.to_sym] || @args[name.to_sym]

      # Set a local variable (used within functions)
      def set_local(name, value) = @locals[name.to_sym] = value

      # Track a message/term ID to detect circular references
      def track(id)
        if @dirty.include?(id)
          add_error("Circular reference detected: #{id}")
          return false
        end

        @dirty.add(id)
        true
      end

      # Release tracking of a message/term ID
      def release(id) = @dirty.delete(id)

      # Add an error to the collection
      def add_error(message) = @errors << message

      # Check if an ID is currently being tracked (circular reference check)
      def tracking?(id) = @dirty.include?(id)

      # Create a child scope (for function calls)
      def child_scope(**)
        child = self.class.new(@bundle, **@args, **)
        child.instance_variable_set(:@locals, @locals.dup)
        child.instance_variable_set(:@dirty, @dirty.dup)
        child
      end

      # Reset locals (used in some resolution contexts)
      def clear_locals = @locals.clear

      # Get all available variables (locals + args)
      def all_variables = @args.merge(@locals)
    end
  end
end
