# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::CanAssets
  extend ActiveSupport::Concern

=begin

get all assets / related models for this user

  user = User.find(123)
  result = user.assets(assets_if_exists)

returns

  result = {
    :User => {
      123  => user_model_123,
      1234 => user_model_1234,
    }
  }

=end

  def assets(data = {})

    app_model = self.class.to_app_model

    if !data[ app_model ]
      data[ app_model ] = {}
    end
    if !data[ app_model ][ id ]
      data[ app_model ][ id ] = attributes_with_association_ids
    end

    return data if !self['created_by_id'] && !self['updated_by_id']

    app_model_user = User.to_app_model
    %w[created_by_id updated_by_id].each do |local_user_id|
      next if !self[ local_user_id ]
      next if data[ app_model_user ] && data[ app_model_user ][ self[ local_user_id ] ]

      user = User.lookup(id: self[ local_user_id ])
      next if !user

      data = user.assets(data)
    end
    data
  end

=begin

get assets and record_ids of selector

  model = Model.find(123)

  assets = model.assets_of_selector('attribute_name_of_selector', assets)

=end

  def assets_of_selector(selector, assets = {})

    # get assets of condition
    models = Models.all
    send(selector).each do |item, content|
      attribute = item.split('.')
      next if !attribute[1]

      begin
        attribute_class = attribute[0].to_classname.constantize
      rescue => e
        next if attribute[0] == 'article'
        next if attribute[0] == 'customer'
        next if attribute[0] == 'execution_time'

        logger.error "Unable to get asset for '#{attribute[0]}': #{e.inspect}"
        next
      end

      if attribute_class == ::Notification
        next if content['recipient'].blank?

        attribute_ref_class = ::User
        item_ids            = []
        Array(content['recipient']).each do |identifier|
          next if identifier !~ %r{\Auserid_(\d+)\z}

          item_ids.push($1)
        end
      else
        reflection = attribute[1].sub(%r{_id$}, '')
        next if !models[attribute_class]
        next if !models[attribute_class][:reflections]
        next if !models[attribute_class][:reflections][reflection]
        next if !models[attribute_class][:reflections][reflection].klass

        attribute_ref_class = models[attribute_class][:reflections][reflection].klass
        item_ids            = Array(content['value'])
      end

      item_ids.each do |item_id|
        next if item_id.blank?

        attribute_object = attribute_ref_class.lookup(id: item_id)
        next if !attribute_object

        assets = attribute_object.assets(assets)
      end
    end
    assets
  end

  def assets_added_to?(data)
    data.dig(self.class.to_app_model, id).present?
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

return object and assets

  data = Model.full(123)
  data = {
    id:     123,
    assets: assets,
  }

=end

    def full(id)
      object = find(id)
      assets = object.assets({})
      {
        id:     object.id,
        assets: assets,
      }
    end

=begin

get assets of object list

  list = [
    {
      object => 'Ticket',
      o_id   => 1,
    },
    {
      object => 'User',
      o_id   => 121,
    },
  ]

  assets = Model.assets_of_object_list(list, assets)

=end

    def assets_of_object_list(list, assets = {})
      list.each do |item|
        require_dependency item['object'].to_filename
        record = item['object'].constantize.lookup(id: item['o_id'])
        next if record.blank?

        assets = record.assets(assets)
        if item['created_by_id'].present?
          user = User.find(item['created_by_id'])
          assets = user.assets(assets)
        end
        if item['updated_by_id'].present?
          user = User.find(item['updated_by_id'])
          assets = user.assets(assets)
        end
      end
      assets
    end
  end

=begin

Compiles an assets hash for given items

@param items  [Array<CanAssets>] list of items responding to @see #assets
@param data   [Hash] given collection. Empty {} or assets collection in progress
@param suffix [String] try to use non-default assets method
@return [Hash] collection including assets of items

@example
  list = Ticket.all
  ApplicationModel::CanAssets.reduce(list, {})

=end

  def self.reduce(items, data = {}, suffix = nil)
    items.reduce(data) do |memo, elem|
      method_name = if suffix.present? && elem.respond_to?("assets_#{suffix}")
                      "assets_#{suffix}"
                    else
                      :assets
                    end

      elem.send method_name, memo
    end
  end
end
