# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Zendesk::UserField < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::User',
      'Import::Zendesk::ObjectAttribute::SanitizedType',
      'Import::Zendesk::ObjectAttribute::SanitizedName',
      'Import::Zendesk::ObjectAttribute::Add',
      'Import::Zendesk::ObjectAttribute::FieldMap',
    ]
  end
end
