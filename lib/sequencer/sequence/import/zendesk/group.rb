# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Zendesk
        class Group < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::Group',
              'Import::Zendesk::Group::Mapping',
              'Import::Common::Model::Attributes::AddByIds',
              'Import::Common::Model::FindBy::Name',
              'Import::Common::Model::Update',
              'Import::Common::Model::Create',
              'Import::Common::Model::Save',
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
