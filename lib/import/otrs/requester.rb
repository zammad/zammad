module Import
  module OTRS
    module Requester
      extend Import::Helper

      # rubocop:disable Style/ModuleFunction
      extend self

      def load(object, args = {})

        @cache ||= {}
        if args.empty? && @cache[object]
          return @cache[object]
        end

        result = request_result(
          Subaction: 'Export',
          Object:    object,
          Limit:     args[:limit]  || '',
          Offset:    args[:offset] || '',
          Diff:      args[:diff] ? 1 : 0
        )

        return result if !args.empty?
        @cache[object] = result
        @cache[object]
      end

      def list
        request_result(Subaction: 'List')
      end

      # TODO: refactor to something like .connected?
      def connection_test
        result = request_json({})
        return true if result['Success']
        raise 'API key not valid!'
      end

      private

      def request_result(params)
        response = request_json(params)
        response['Result']
      end

      def request_json(params)
        response = post(params)
        result   = handle_response(response)

        return result if result

        raise 'Invalid response'
      end

      def handle_response(response)
        encoded_body = Encode.conv('utf8', response.body.to_s)
        JSON.parse(encoded_body)
      end

      def post(params)
        url             = Setting.get('import_otrs_endpoint')
        params[:Action] = 'ZammadMigrator'
        params[:Key]    = Setting.get('import_otrs_endpoint_key')

        log 'POST: ' + url
        log 'PARAMS: ' + params.inspect

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
