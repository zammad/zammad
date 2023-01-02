# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Freshdesk::TimeEntry < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::Ticket::TimeAccounting',
      'Import::Freshdesk::TimeEntry::Mapping',
      'Import::Common::Model::FindBy::TimeAccountingAttributes',
      'Import::Common::Model::Update',
      'Import::Common::Model::Create',
      'Import::Common::Model::Save',
    ]
  end
end
