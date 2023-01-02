# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  def self.default_collections(user)

    # auto population collections, store all here
    default_collection = {}
    assets = user.assets({})

    # load collections to deliver from external files
    dir = File.expand_path('..', __dir__)
    files = Dir.glob("#{dir}/lib/session_helper/collection_*.rb")
    files.each do |file|
      file =~ %r{/(session_helper/collection_.*)\.rb\z}
      (default_collection, assets) = $1.camelize.constantize.session(default_collection, assets, user)
    end

    [default_collection, assets]
  end

  def self.models(user = nil)
    models = {}
    objects = ObjectManager.list_objects
    objects.each do |object|
      attributes = ObjectManager::Object.new(object).attributes(user)
      models[object] = attributes
    end
    models
  end

  def self.cleanup_expired

    # delete temp. sessions
    ActiveRecord::SessionStore::Session.where('persistent IS NULL AND updated_at < ?', 2.hours.ago).delete_all

    # web sessions not updated the last x days
    ActiveRecord::SessionStore::Session.where('updated_at < ?', 60.days.ago).delete_all

  end

  def self.get(id)
    ActiveRecord::SessionStore::Session.find_by(id: id)
  end

  def self.list(limit = 10_000)
    ActiveRecord::SessionStore::Session.order(updated_at: :desc).limit(limit)
  end

  def self.destroy(id)
    session = ActiveRecord::SessionStore::Session.find_by(id: id)
    return if !session

    session.destroy
  end
end
