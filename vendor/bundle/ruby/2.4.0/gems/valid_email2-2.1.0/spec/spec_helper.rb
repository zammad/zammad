$:.unshift File.expand_path("../lib",__FILE__)
require "valid_email2"

class TestModel
  include ActiveModel::Validations

  def initialize(attributes = {})
    @attributes = attributes
  end

  def read_attribute_for_validation(key)
    @attributes[key]
  end
end
