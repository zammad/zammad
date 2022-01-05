# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Freshdesk
        class PermissionCheck < Sequencer::Sequence::Base

          def self.expecting
            [:permission_present]
          end

          def self.sequence
            [
              'Freshdesk::PermissionPresent',
            ]
          end
        end
      end
    end
  end
end
