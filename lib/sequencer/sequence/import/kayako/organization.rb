# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Kayako
        class Organization < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::Organization',
              'Import::Kayako::Organization::Mapping',
              'Import::Kayako::Mapping::CustomFields',
              'Import::Common::Model::Attributes::AddByIds',
              'Import::Common::Model::FindBy::Name',
              'Import::Common::Model::Update',
              'Import::Common::Model::Create',
              'Import::Common::Model::Save',
              'Import::Kayako::MapId',
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
