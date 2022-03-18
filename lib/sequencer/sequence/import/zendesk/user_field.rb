# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Zendesk
        class UserField < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::User',
              'Import::Zendesk::ObjectAttribute::SanitizedType',
              'Import::Zendesk::ObjectAttribute::SanitizedName',
              'Import::Zendesk::ObjectAttribute::Add',
            ]
          end
        end
      end
    end
  end
end
