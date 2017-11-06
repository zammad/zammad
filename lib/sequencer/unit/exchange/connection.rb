class Sequencer
  class Unit
    module Exchange
      class Connection < Sequencer::Unit::Base

        uses :ews_config
        provides :ews_connection

        def process
          # check if EWS connection is already given (sub sequence)
          return if state.provided?(:ews_connection)

          state.provide(:ews_connection) do
            Viewpoint::EWSClient.new(
              config[:endpoint],
              config[:user],
              config[:password],
              additional_opts
            )
          end
        end

        private

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
