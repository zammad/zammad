# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Freshdesk::ContactField < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::User',
      'Import::Freshdesk::ObjectAttribute::Skip',
      'Import::Freshdesk::ObjectAttribute::SanitizedName',
      'Import::Freshdesk::ObjectAttribute::Config',
      'Import::Freshdesk::ObjectAttribute::Add',
      'Import::Freshdesk::ObjectAttribute::MigrationExecute',
      'Import::Freshdesk::ObjectAttribute::FieldMap',
    ]
  end
end
