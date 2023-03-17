# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Freshdesk::Full < Sequencer::Sequence::Base

  def self.sequence
    [
      'Import::Common::ImportMode::Check',
      'Import::Common::SystemInitDone::Check',
      'Import::Common::ImportJob::DryRun',
      'Import::Freshdesk::TimeEntry::Available',
      'Import::Freshdesk::IdMap',
      'Import::Freshdesk::Groups',
      'Import::Freshdesk::FieldMap',
      'Import::Freshdesk::CompanyFields',
      'Import::Freshdesk::Companies',
      'Import::Freshdesk::Agents',
      'Import::Freshdesk::Agents::GroupsPermissions',
      'Import::Freshdesk::ContactFields',
      'Import::Freshdesk::Contacts::Default',
      'Import::Freshdesk::Contacts::Blocked',
      'Import::Freshdesk::Contacts::Deleted',
      'Import::Freshdesk::TicketFields',
      'Import::Freshdesk::Tickets',
      'Import::Common::SystemInitDone::Set',
      'Import::Common::ImportMode::Unset',
    ]
  end
end
