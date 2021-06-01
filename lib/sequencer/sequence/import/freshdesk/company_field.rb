# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Freshdesk
        class CompanyField < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::Organization',
              'Import::Freshdesk::ObjectAttribute::Skip',
              'Import::Freshdesk::ObjectAttribute::SanitizedName',
              'Import::Freshdesk::ObjectAttribute::Config',
              'Import::Freshdesk::ObjectAttribute::Add',
              'Import::Freshdesk::ObjectAttribute::MigrationExecute',
              'Import::Freshdesk::ObjectAttribute::FieldMap',
            ]
          end
        end
      end
    end
  end
end
