# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Kayako::OrganizationField < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::Organization',
      'Import::Kayako::ObjectAttribute::Skip',
      'Import::Kayako::ObjectAttribute::SanitizedName',
      'Import::Kayako::ObjectAttribute::Config',
      'Import::Kayako::ObjectAttribute::Add',
      'Import::Kayako::ObjectAttribute::MigrationExecute',
      'Import::Kayako::ObjectAttribute::FieldMap',
    ]
  end
end
