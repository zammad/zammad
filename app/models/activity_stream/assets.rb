# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ActivityStream
  module Assets
    extend ActiveSupport::Concern

=begin

get all assets / related models for this activity stream item

  activity_stream = ActivityStream.find(123)
  result = activity_stream.assets(assets_if_exists)

returns

  result = {
    :ActivityStream => {
      123  => activity_stream_model_123,
      1234 => activity_stream_model_1234,
    }
  }

=end

    def assets(data)

      app_model = self.class.to_app_model

      if !data[ app_model ]
        data[ app_model ] = {}
      end
      return data if data[ app_model ][ id ]

      local_attributes = attributes_with_association_ids

      local_attributes['object'] = ObjectLookup.by_id(local_attributes['activity_stream_object_id'])
      local_attributes['type']   = TypeLookup.by_id(local_attributes['activity_stream_type_id'])

      # set temp. current attributes to assets pool to prevent
      # loops, will be updated with lookup attributes later
      data[ app_model ][ id ] = local_attributes

      ApplicationModel.assets_of_object_list([local_attributes], data)

      return data if !self['created_by_id']

      app_model_user = User.to_app_model
      %w[created_by_id].each do |local_user_id|
        next if !self[ local_user_id ]
        next if data[ app_model_user ] && data[ app_model_user ][ self[ local_user_id ] ]

        user = User.lookup(id: self[ local_user_id ])
        next if !user

        data = user.assets(data)
      end
      data
    end
  end
end
