# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Channel
  module Assets
    extend ActiveSupport::Concern

=begin

get all assets / related models for this channel

  channel = Channel.find(123)
  result = channel.assets(assets_if_exists)

returns

  result = {
    :channels => {
      123  => channel_model_123,
      1234 => channel_model_1234,
    }
  }

=end

    def assets(data = {})

      app_model = self.class.to_app_model

      if !data[ app_model ]
        data[ app_model ] = {}
      end
      return data if data[ app_model ][ id ]

      attributes = attributes_with_association_ids

      # remove passwords if use is no admin
      access = false
      if UserInfo.current_user_id
        user = User.lookup(id: UserInfo.current_user_id)
        if user.permissions?('admin.channel')
          access = true
        end
      end
      if !access
        %w[inbound outbound].each do |key|
          if attributes['options'] && attributes['options'][key] && attributes['options'][key]['options']
            attributes['options'][key]['options'].delete('password')
          end
        end
      end

      data[ self.class.to_app_model ][ id ] = attributes

      return data if !self['created_by_id'] && !self['updated_by_id']

      %w[created_by_id updated_by_id].each do |local_user_id|
        next if !self[ local_user_id ]
        next if data[ User.to_app_model ] && data[ User.to_app_model ][ self[ local_user_id ] ]

        user = User.lookup(id: self[ local_user_id ])
        next if !user

        data = user.assets(data)
      end
      data
    end

  end
end
