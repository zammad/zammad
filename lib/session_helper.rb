# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module SessionHelper
  def self.json_hash(user)
    collections, assets = default_collections(user)
    {
      session:     user.filter_unauthorized_attributes(user.filter_attributes(user.attributes)),
      models:      models(user),
      collections: collections,
      assets:      assets,
    }
  end

  def self.json_hash_error(error)
    {
      error:       error.message,
      models:      models,
      collections: {
        Locale.to_app_model     => Locale.where(active: true),
        PublicLink.to_app_model => PublicLink.all,
      }
    }
  end

  def self.default_collections(user)

    # auto population collections, store all here
    default_collection = {}
    assets = user.assets({})

    # load collections to deliver from external files
    dir = File.expand_path('..', __dir__)
    files = Dir.glob("#{dir}/lib/session_helper/collection_*.rb")
    files.each do |file|
      file =~ %r{/(session_helper/collection_.*)\.rb\z}
      class_name = $1.camelize
      next if !Object.const_defined?(class_name) && Rails.env.production?

      (default_collection, assets) = class_name.constantize.session(default_collection, assets, user)
    end

    [default_collection, assets]
  end

  def self.models(user = nil)
    return models_public if user.blank?

    ObjectManager.list_objects.each_with_object({}) do |object, models|
      attributes = ObjectManager::Object.new(object).attributes(user)
      models[object] = attributes
    end
  end

  def self.models_public
    allowed_user_attributes = %w[firstname lastname email password]

    user_attributes = ObjectManager::Object
      .new('User')
      .attributes(nil, skip_permission: true)
      .select { |attribute| allowed_user_attributes.include?(attribute[:name]) }

    {
      'User' => user_attributes,
    }
  end

  def self.cleanup_expired

    # delete temp. sessions
    ActiveRecord::SessionStore::Session
      .where(persistent: nil, updated_at: ...2.hours.ago)
      .delete_all

    # web sessions not updated the last x days
    ActiveRecord::SessionStore::Session
      .where(updated_at: ...60.days.ago)
      .delete_all
  end

  def self.get(id)
    ActiveRecord::SessionStore::Session.find_by(id: id)
  end

  def self.list(limit = 10_000)
    ActiveRecord::SessionStore::Session.reorder(updated_at: :desc).limit(limit)
  end

  def self.destroy(id)
    ActiveRecord::SessionStore::Session
      .find_by(id: id)
      &.destroy
  end
end
