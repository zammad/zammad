# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Sequence
    module Exchange
      module Folder
        class Attributes < Sequencer::Sequence::Base

          def self.sequence
            [
              'Exchange::Connection',
              'Exchange::Folder::Attributes',
            ]
          end
        end
      end
    end
  end
end
