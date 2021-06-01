# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
                  if response.success?
                    state.provide(:response, response)
                  else
                    logger.error "Skipping. Error while downloading Attachment from '#{resource.content_url}': #{response.error}"
                    state.provide(:action, :skipped)
                  end
                end

                private

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
