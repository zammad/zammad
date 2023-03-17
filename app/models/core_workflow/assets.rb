# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow
  module Assets
    extend ActiveSupport::Concern

    def assets(data)
      app_model_workflow = CoreWorkflow.to_app_model
      data[ app_model_workflow ] ||= {}

      return data if data[ app_model_workflow ][ id ]

      data = assets_object(data)
      assets_user(data)
    end
  end

  def assets_object(data)
    app_model_workflow = CoreWorkflow.to_app_model
    data[ app_model_workflow ][ id ] = attributes_with_association_ids
    data = assets_of_selector('condition_selected', data)
    data = assets_of_selector('condition_saved', data)
    assets_of_selector('perform', data)
  end

  def assets_user(data)
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
