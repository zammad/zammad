# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Exchange::AttributeMapper::AttributeExamples < Sequencer::Unit::Common::AttributeMapper

  def self.map
    {
      ews_attributes_examples: :attributes,
    }
  end
end
