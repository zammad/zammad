# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Kayako
        class ConnectionTest < Sequencer::Sequence::Base
          def self.expecting
            [:connected]
          end

          def self.sequence
            [
              'Kayako::Connected',
            ]
          end
        end
      end
    end
  end
end
