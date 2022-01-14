# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        class ModelClass < Sequencer::Unit::Common::Provider::Named

          uses :object

          MAP = {
            'Organization' => ::Organization,
            'User'         => ::User,
            'Team'         => ::Group,
            'Case'         => ::Ticket,
            'Post'         => ::Ticket::Article,
            'TimeEntry'    => ::Ticket::TimeAccounting,
          }.freeze

          private

          def model_class
            MAP[object]
          end
        end
      end
    end
  end
end
