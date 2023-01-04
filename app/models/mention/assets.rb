# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Mention
  module Assets
    extend ActiveSupport::Concern

    def assets_attributes(data)
      app_model = self.class.to_app_model

      data[ app_model ] ||= {}
      return data if data[ app_model ][ id ]

      data[ app_model ][ id ] = attributes_with_association_ids

      data
    end

    def assets(data)
      assets_attributes(data)

      if mentionable.present?
        data = mentionable.assets(data)
      end

      user.assets(data)
    end
  end
end
