# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Report::Profile
  module Assets
    extend ActiveSupport::Concern

    def assets(data)
      app_model_report_profile = Report::Profile.to_app_model
      data[ app_model_report_profile ] ||= {}

      return data if data[ app_model_report_profile ][ id ]

      data[ app_model_report_profile ][ id ] = attributes_with_association_ids
      data = assets_of_selector('condition', data)

      app_model_user = User.to_app_model
      data[ app_model_user ] ||= {}

      %w[created_by_id updated_by_id].each do |local_user_id|
        next if !self[ local_user_id ]
        next if data[ app_model_user ][ self[ local_user_id ] ]

        user = User.lookup(id: self[ local_user_id ])
        next if !user

        data = user.assets(data)
      end
      data
    end
  end
end
