# frozen_string_literal: true

# Shared examples for validating FTL resource structure
# These examples provide common validation for all FTL fixture-based tests.
RSpec.shared_examples "a valid FTL resource" do
  # Verify that the result is a Resource object
  it "returns a Resource object" do
    expect(result).to be_a(Foxtail::AST::Resource)
  end

  # Verify that the parsed result is not nil
  it "has a valid result" do
    expect(result).not_to be_nil
  end

  # Verify that the expected JSON is not nil
  it "has valid expected JSON" do
    expect(expected_json).not_to be_nil
  end

  # Verify that the resource type is correct
  it "has the correct resource type" do
    resource_hash = resource_to_hash(result)
    expect(resource_hash["type"]).to eq(expected_json["type"])
  end

  # Verify that the body exists
  it "has a body array" do
    resource_hash = resource_to_hash(result)
    expect(resource_hash["body"]).to be_an(Array)
  end
end
