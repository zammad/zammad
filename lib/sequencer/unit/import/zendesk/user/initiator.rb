# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module User
          class Initiator < Sequencer::Unit::Base

            uses :resource
            provides :initiator

            def process
              state.provide(:initiator, initiator?)
            end

            private

            def initiator?
              return false if resource.email.blank?

              resource.email == Setting.get('import_zendesk_endpoint_username')
            end
          end
        end
      end
    end
  end
end
