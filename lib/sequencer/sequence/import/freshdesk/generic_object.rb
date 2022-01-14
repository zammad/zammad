# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Freshdesk
        class GenericObject < Sequencer::Sequence::Base

          def self.sequence
            [
              'Import::Freshdesk::Request',
              'Import::Freshdesk::Resources',
              'Import::Freshdesk::ModelClass',
              'Import::Freshdesk::ObjectCount',
              'Import::Common::ImportJob::Statistics::Update',
              'Import::Common::ImportJob::Statistics::Store',
              'Import::Freshdesk::Perform',
            ]
          end
        end
      end
    end
  end
end
