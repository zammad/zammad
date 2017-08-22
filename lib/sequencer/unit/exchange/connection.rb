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
            config   = ews_config
            config ||= ::Import::Exchange.config

            Viewpoint::EWSClient.new(config[:endpoint], config[:user], config[:password])
          end
        end
      end
    end
  end
end
