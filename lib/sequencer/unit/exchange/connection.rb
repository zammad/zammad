# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Exchange
      class Connection < Sequencer::Unit::Common::Provider::Fallback

        uses :ews_config
        provides :ews_connection

        private

        def ews_connection
          Viewpoint::EWSClient.new(
            config[:endpoint],
            config[:user],
            config[:password],
            additional_opts
          )
        end

        def config
          @config ||= begin
            ews_config || ::Import::Exchange.config
          end
        end

        def additional_opts
          @additional_opts ||= begin
            http_opts
          end
        end

        def http_opts
          return {} if config[:disable_ssl_verify].blank?

          {
            http_opts: {
              ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
            }
          }
        end
      end
    end
  end
end
