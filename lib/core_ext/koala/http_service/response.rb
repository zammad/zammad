# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'koala/http_service/response'

module Koala
  module HTTPService
    class Response
      # https://github.com/arsduo/koala/blob/v3.7.0/lib/koala/http_service/response.rb#L13-L17
      # json 3 rejects the obsolete quirks_mode option; json >= 2 parses top-level scalars without it.
      # Remove once Koala stops passing it.
      def data
        @data ||= JSON.parse(body) if !body.empty?
      end
    end
  end
end
