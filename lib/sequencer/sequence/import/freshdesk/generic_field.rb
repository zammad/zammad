# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Freshdesk
        class GenericField < Sequencer::Sequence::Base

          def self.sequence
            [
              'Import::Freshdesk::Request',
              'Import::Freshdesk::Resources',
              'Import::Freshdesk::Perform',
            ]
          end
        end
      end
    end
  end
end
