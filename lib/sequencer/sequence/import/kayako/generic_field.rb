# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Kayako
        class GenericField < Sequencer::Sequence::Base

          def self.sequence
            [
              'Import::Kayako::Request',
              'Import::Kayako::Resources',
              'Import::Kayako::Perform',
            ]
          end
        end
      end
    end
  end
end
