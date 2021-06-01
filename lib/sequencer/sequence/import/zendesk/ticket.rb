# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Zendesk
        class Ticket < Sequencer::Sequence::Base

          def self.sequence
            [
              'Import::Zendesk::Ticket::Skip::Deleted',
              'Import::Zendesk::Ticket::UserID',
              'Import::Zendesk::Ticket::OwnerID',
              'Import::Zendesk::Ticket::GroupID',
              'Import::Zendesk::Ticket::OrganizationID',
              'Import::Zendesk::Ticket::PriorityID',
              'Import::Zendesk::Ticket::StateID',
              'Import::Zendesk::Common::ArticleSenderID',
              'Import::Zendesk::Common::ArticleTypeID',
              'Import::Zendesk::Ticket::Subject',
              'Import::Zendesk::Ticket::CustomFields',
              'Import::Zendesk::Ticket::Mapping',
              'Common::ModelClass::Ticket',
              'Import::Common::Model::FindBy::Id',
              'Import::Common::Model::Update',
              'Import::Common::Model::Create',
              'Import::Common::Model::Save',
              'Import::Common::Model::ResetPrimaryKeySequence',
              'Import::Zendesk::Ticket::Tags',
              'Import::Zendesk::Ticket::Comments',
              'Import::Common::Model::Statistics::Diff::ModelKey',
              'Import::Common::ImportJob::Statistics::Update',
              'Import::Common::ImportJob::Statistics::Store',
            ]
          end
        end
      end
    end
  end
end
