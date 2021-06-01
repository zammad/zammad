# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class History
  module Assets
    extend ActiveSupport::Concern

=begin

get all assets / related models for this history entry

  history = History.find(123)
  result = history.assets(assets_if_exists)

returns

  result = {
    :users => {
      123  => user_model_123,
      1234 => user_model_1234,
    }
  }

=end

    def assets(data)

      app_model = User.to_app_model

      if !data[ app_model ] || !data[ app_model ][ self['created_by_id'] ]
        user = User.lookup(id: self['created_by_id'])
        if user
          data = user.assets(data)
        end
      end

      data
    end
  end
end
