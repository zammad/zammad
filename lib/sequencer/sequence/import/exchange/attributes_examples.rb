# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Exchange::AttributesExamples < Sequencer::Sequence::Base

  def self.expecting
    [:attributes]
  end

  def self.sequence
    [
      'Exchange::Connection',
      'Exchange::Folders::ByIds',
      'Import::Exchange::AttributeExamples',
      'Import::Exchange::AttributeMapper::AttributeExamples',
    ]
  end
end
