class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          module Comment
            module Attachment
              class Request < Sequencer::Unit::Base
                prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

                skip_action :skipped

                uses :resource
                provides :response, :action

                def process
                  if failed?
                    state.provide(:action, :skipped)
                  else
                    state.provide(:response, response)
                  end
                end

                private

                def failed?
                  return false if response.success?

                  logger.error response.error
                  true
                end

                def response
                  @response ||= begin
                    UserAgent.get(
                      resource.content_url,
                      {},
                      {
                        open_timeout: 20,
                        read_timeout: 240,
                      },
                    )
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
