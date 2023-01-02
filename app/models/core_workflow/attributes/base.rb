# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Attributes::Base
  def initialize(attributes:, attribute:)
    @attributes = attributes
    @attribute = attribute
  end

  def values
    []
  end
end
