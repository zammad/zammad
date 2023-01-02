# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Zendesk::Organization < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::Organization',
      'Import::Zendesk::Organization::Mapping',
      'Import::Zendesk::Organization::CustomFields',
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
