# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Zendesk
        class Full < Sequencer::Sequence::Base

          def self.sequence
            [
              'Import::Common::ImportMode::Check',
              'Import::Common::SystemInitDone::Check',
              'Zendesk::Client',
              'Import::Zendesk::ObjectsTotalCount',
              'Import::Common::ImportJob::Statistics::Update',
              'Import::Common::ImportJob::Statistics::Store',
              'Import::Common::ImportJob::DryRun',
              'Import::Zendesk::Groups',
              'Import::Zendesk::OrganizationFields',
              'Import::Zendesk::Organizations',
              'Import::Zendesk::UserFields',
              'Import::Zendesk::UserGroupMap',
              'Import::Zendesk::Users',
              'Import::Zendesk::TicketFields',
              'Import::Zendesk::Tickets',
              'Import::Common::SystemInitDone::Set',
              'Import::Common::ImportMode::Unset',
            ]
          end
        end
      end
    end
  end
end
