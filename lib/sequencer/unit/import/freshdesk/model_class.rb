# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        class ModelClass < Sequencer::Unit::Common::Provider::Named

          uses :object

          MAP = {
            'Company'      => ::Organization,
            'Agent'        => ::User,
            'Contact'      => ::User,
            'Group'        => ::Group,
            'Ticket'       => ::Ticket,
            'Conversation' => ::Ticket::Article,
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
