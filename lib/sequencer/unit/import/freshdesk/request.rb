# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        class Request < Sequencer::Unit::Common::Provider::Attribute
          extend ::Sequencer::Unit::Import::Freshdesk::Requester

          uses :object, :request_params
          provides :response

          private

          def response

            builder = backend.new(
              object:         object,
              request_params: request_params
            )

            self.class.request(
              api_path: builder.api_path,
              params:   builder.params,
            )
          end

          def backend
            "::Sequencer::Unit::Import::Freshdesk::Request::#{object}".safe_constantize || ::Sequencer::Unit::Import::Freshdesk::Request::Generic
          end
        end
      end
    end
  end
end
