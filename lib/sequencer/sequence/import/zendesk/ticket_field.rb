# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Zendesk::TicketField < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::Ticket',
      'Import::Zendesk::TicketField::CheckCustom',
      'Import::Zendesk::ObjectAttribute::SanitizedType',
      'Import::Zendesk::TicketField::SanitizedName',
      'Import::Zendesk::ObjectAttribute::Add',
    ]
  end
end
