# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Request < Sequencer::Unit::Common::Provider::Attribute
  class Generic
    attr_reader :object, :request_params

    def initialize(object:, request_params:)
      @object         = object
      @request_params = request_params
    end

    def api_path
      object.pluralize.underscore
    end

    def params
      request_params.merge(
        per_page: 100,
      )
    end
  end
end
