# frozen_string_literal: true

require "locale"

RSpec.describe Foxtail::Bundle::Scope do
  let(:bundle) { Foxtail::Bundle.new(locale("en")) }
  let(:args) { {:name => "World", :count => 5, "email" => "test@example.com"} }
  let(:scope) { Foxtail::Bundle::Scope.new(bundle, args) }

  describe "#initialize" do
    it "sets bundle and args" do
      expect(scope.bundle).to eq(bundle)
      expect(scope.args).to eq(args)
    end

    it "initializes empty locals and errors" do
      expect(scope.locals).to eq({})
      expect(scope.errors).to eq([])
    end

    it "initializes empty dirty set" do
      expect(scope.dirty).to be_a(Set)
      expect(scope.dirty).to be_empty
    end

    it "works without args" do
      empty_scope = Foxtail::Bundle::Scope.new(bundle)
      expect(empty_scope.args).to eq({})
    end
  end

  describe "#variable" do
    it "gets variables from args (symbol keys)" do
      expect(scope.variable("name")).to eq("World")
      expect(scope.variable("count")).to eq(5)
    end

    it "gets variables from args (string keys)" do
      expect(scope.variable("email")).to eq("test@example.com")
    end

    it "gets local variables first" do
      scope.set_local("name", "Local Value")
      expect(scope.variable("name")).to eq("Local Value")
    end

    it "returns nil for nonexistent variables" do
      expect(scope.variable("nonexistent")).to be_nil
    end

    it "prioritizes locals over args" do
      scope.set_local("count", 100)
      expect(scope.variable("count")).to eq(100)
    end
  end

  describe "#set_local" do
    it "sets local variables as strings" do
      scope.set_local("local_var", "value")
      expect(scope.locals["local_var"]).to eq("value")
    end

    it "converts keys to strings" do
      scope.set_local(:symbol_key, "value")
      expect(scope.locals["symbol_key"]).to eq("value")
    end

    it "overwrites existing locals" do
      scope.set_local("var", "first")
      scope.set_local("var", "second")
      expect(scope.locals["var"]).to eq("second")
    end
  end

  describe "circular reference detection" do
    describe "#track and #release" do
      it "tracks message/term IDs" do
        expect(scope.track("hello")).to be true
        expect(scope.dirty).to include("hello")
      end

      it "detects circular references" do
        scope.track("hello")
        expect(scope.track("hello")).to be false
        expect(scope.errors).to include("Circular reference detected: hello")
      end

      it "releases tracked IDs" do
        scope.track("hello")
        scope.release("hello")
        expect(scope.dirty).not_to include("hello")
      end

      it "allows re-tracking after release" do
        scope.track("hello")
        scope.release("hello")
        expect(scope.track("hello")).to be true
      end
    end

    describe "#tracking?" do
      it "returns true for tracked IDs" do
        scope.track("hello")
        expect(scope.tracking?("hello")).to be true
      end

      it "returns false for untracked IDs" do
        expect(scope.tracking?("hello")).to be false
      end

      it "returns false after release" do
        scope.track("hello")
        scope.release("hello")
        expect(scope.tracking?("hello")).to be false
      end
    end
  end

  describe "#add_error" do
    it "adds errors to the collection" do
      scope.add_error("Test error")
      expect(scope.errors).to include("Test error")
    end

    it "accumulates multiple errors" do
      scope.add_error("Error 1")
      scope.add_error("Error 2")
      expect(scope.errors).to eq(["Error 1", "Error 2"])
    end
  end

  describe "#child_scope" do
    before do
      scope.set_local("local_var", "local_value")
      scope.track("tracked_id")
      scope.add_error("Parent error")
    end

    it "creates a child scope with merged args" do
      child_args = {child_key: "child_value"}
      child = scope.child_scope(child_args)

      expect(child.bundle).to eq(bundle)
      expect(child.args).to include(args)
      expect(child.args).to include(child_args)
    end

    it "copies locals from parent" do
      child = scope.child_scope
      expect(child.locals).to eq(scope.locals)

      # Modifications don't affect parent
      child.set_local("child_local", "value")
      expect(scope.locals).not_to have_key("child_local")
    end

    it "copies dirty set from parent" do
      child = scope.child_scope
      expect(child.dirty).to eq(scope.dirty)

      # Modifications don't affect parent
      child.track("child_id")
      expect(scope.dirty).not_to include("child_id")
    end

    it "starts with empty errors" do
      child = scope.child_scope
      expect(child.errors).to be_empty
    end
  end

  describe "#clear_locals" do
    it "clears all local variables" do
      scope.set_local("var1", "value1")
      scope.set_local("var2", "value2")

      scope.clear_locals
      expect(scope.locals).to be_empty
    end

    it "doesn't affect args" do
      scope.clear_locals
      expect(scope.variable("name")).to eq("World")
    end
  end

  describe "#all_variables" do
    before do
      scope.set_local("local_var", "local_value")
      scope.set_local("name", "overridden") # Override args
    end

    it "returns merged args and locals" do
      all_vars = scope.all_variables
      expect(all_vars).to include(args)
      expect(all_vars["local_var"]).to eq("local_value")
    end

    it "prioritizes locals over args in merged result" do
      all_vars = scope.all_variables
      expect(all_vars["name"]).to eq("overridden")
    end

    it "doesn't modify original args or locals" do
      original_args = scope.args.dup
      original_locals = scope.locals.dup

      scope.all_variables

      expect(scope.args).to eq(original_args)
      expect(scope.locals).to eq(original_locals)
    end
  end
end
