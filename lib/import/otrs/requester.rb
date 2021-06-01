# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS

    # @!attribute [rw] retry_sleep
    #   @return [Number] the sleep time between the request retries
    module Requester
      extend Import::Helper
      extend self

      attr_accessor :retry_sleep

      # Loads entries of the given object.
      #
      # @param object [String] the name of OTRS object
      # @param [Hash] opts the options to load entries.
      # @option opts [String] :limit the maximum amount of entries that should get loaded
      # @option opts [String] :offset the offset where the entry listing should start
      # @option opts [Boolean] :diff request only changed/added entries since the last import
      #
      # @example
      #   Import::OTRS::Requester.load('Ticket', offset: '208', limit: '1')
      #   #=> [{'TicketNumber':'1234', ...}, ...]
      #
      #   Import::OTRS::Requester.load('State', offset: '0', limit: '50')
      #   #=> [{'Name':'pending reminder', ...}, ...]
      #
      # @return [Array<Hash{String => String, Number, nil, Hash, Array}>]
      def load(object, opts = {})

        @cache ||= {}
        if opts.blank? && @cache[object]
          return @cache[object]
        end

        result = request_result(
          Subaction: 'Export',
          Object:    object,
          Limit:     opts[:limit] || '',
          Offset:    opts[:offset] || '',
          Diff:      opts[:diff] ? 1 : 0
        )

        return result if opts.present?

        @cache[object] = result
        @cache[object]
      end

      # Lists the OTRS objects and their amount of importable entries.
      #
      # @example
      #   Import::OTRS::Requester.list #=> {'DynamicFields' => 5, ...}
      #
      # @return [Hash{String => Number}] key = OTRS object, value = amount
      def list
        request_result(Subaction: 'List')
      end

      # Checks if the connection to the OTRS export endpoint works.
      #
      # @todo Refactor to something like .connected?
      #
      # @example
      #   Import::OTRS::Requester.connection_test #=> true
      #
      # @raise [RuntimeError] if the API key is not valid
      #
      # @return [true] always returns true
      def connection_test
        result = request_json({})
        raise 'API key not valid!' if !result['Success']

        true
      end

      private

      def request_result(params)
        tries ||= 1
        response = request_json(params)
        response['Result']
      rescue
        # stop after 3 tries
        raise if tries == 3

        # try again
        tries += 1
        sleep tries * (retry_sleep || 15)
        retry
      end

      def request_json(params)
        response = post(params)
        result   = handle_response(response)
        raise 'Invalid response' if !result

        result
      end

      def handle_response(response)
        encoded_body = response.body.to_utf8(fallback: :read_as_sanitized_binary)
        # remove null bytes otherwise PostgreSQL will fail
        encoded_body.delete('\u0000')
        JSON.parse(encoded_body)
      end

      def post(params)
        url             = Setting.get('import_otrs_endpoint')
        params[:Action] = 'ZammadMigrator'
        params[:Key]    = Setting.get('import_otrs_endpoint_key')

        log "POST: #{url}"
        log "PARAMS: #{params.inspect}"

        response = UserAgent.post(
          url,
          params,
          {
            open_timeout:  10,
            read_timeout:  120,
            total_timeout: 360,
            user:          Setting.get('import_otrs_user'),
            password:      Setting.get('import_otrs_password'),
          },
        )

        if !response
          raise "Can't connect to Zammad Migrator"
        end

        if !response.success?
          log "ERROR: #{response.error}"
          raise 'Zammad Migrator returned an error'
        end
        response
      end
    end
  end
end
