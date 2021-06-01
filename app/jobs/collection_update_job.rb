# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CollectionUpdateJob < ApplicationJob
  include HasActiveJobLock

  def lock_key
    # "CollectionUpdateJob/:model"
    "#{self.class.name}/#{arguments[0]}"
  end

  def perform(model)
    model = model.safe_constantize
    return if model.blank?

    assets = {}
    all = []
    model.order(id: :asc).find_each do |record|
      assets = record.assets(assets)
      all.push record.attributes_with_association_ids
    end

    return if all.blank?

    Sessions.list.each do |client_id, data|
      next if client_id.blank?

      user_id = data&.dig(:user, 'id')
      next if user_id.blank?

      # check permission based access
      if model.collection_push_permission_value.present?
        user = User.lookup(id: user_id)
        next if !user&.permissions?(model.collection_push_permission_value)
      end

      Rails.logger.debug { "push assets for push_collection #{model} for user #{user_id}" }
      Sessions.send(client_id, {
                      data:  assets,
                      event: 'loadAssets',
                    })

      Rails.logger.debug { "push push_collection #{model} for user #{user_id}" }
      Sessions.send(client_id, {
                      event: 'resetCollection',
                      data:  {
                        model.to_app_model => all,
                      },
                    })
    end

  end
end
