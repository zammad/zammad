# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Attributes::Base
  def initialize(attributes:, attribute:)
    @attributes = attributes
    @attribute = attribute
  end

  def values
    []
  end
end
