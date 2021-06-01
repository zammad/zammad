# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Requester
          def request(api_path:, params: nil)
            10.times do |iteration|
              response = perform_request(
                api_path: api_path,
                params:   params,
              )

              return response if response.is_a? Net::HTTPOK

              handle_error response, iteration
            rescue => e
              handle_exception e, iteration
            end
          end

          def handle_error(response, iteration)
            sleep_for = 10
            case response
            when Net::HTTPTooManyRequests
              sleep_for = response.header['retry-after'].to_i + 10
              logger.info "Rate limit: #{response.header.to_hash} (429 Too Many Requests). Sleeping #{sleep_for} seconds and retry (##{iteration + 1}/10)."
            else
              logger.info "Unknown response: #{response.inspect}. Sleeping 10 seconds and retry (##{iteration + 1}/10)."
            end
            sleep sleep_for
          end

          def handle_exception(e, iteration)
            logger.error e
            logger.info "Sleeping 10 seconds after #{e.name} and retry (##{iteration + 1}/10)."
            sleep 10
          end

          def perform_request(api_path:, params: nil)
            uri = URI("#{Setting.get('import_freshdesk_endpoint')}/#{api_path}")
            uri.query = URI.encode_www_form(params) if params.present?
            headers = { 'Content-Type' => 'application/json' }

            Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 600) do |http|
              # for those special moments...
              # http.set_debug_output($stdout)
              request = Net::HTTP::Get.new(uri, headers)
              request.basic_auth(Setting.get('import_freshdesk_endpoint_key'), 'X')
              return http.request(request)
            end
          end
        end
      end
    end
  end
end
