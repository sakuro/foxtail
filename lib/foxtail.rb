# frozen_string_literal: true

require_relative "foxtail/version"
require_relative "foxtail/errors"
require_relative "foxtail/ast/base"
require_relative "foxtail/ast/resource"
require_relative "foxtail/ast/message"
require_relative "foxtail/ast/pattern"
require_relative "foxtail/ast/expression"
require_relative "foxtail/stream"
require_relative "foxtail/parser"
require_relative "foxtail/resource_loader"

module Foxtail
  # Parse FTL source string
  def self.parse(source, resource_id=nil)
    ResourceLoader.new.load_from_string(source, resource_id)
  end

  # Parse FTL file
  def self.parse_file(file_path, resource_id=nil)
    ResourceLoader.new.load_from_file(file_path, resource_id)
  end
end
