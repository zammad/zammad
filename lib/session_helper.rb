module SessionHelper
  def self.default_collections(user)

    # auto population collections, store all here
    default_collection = {}
    assets             = {}

    # load collections to deliver from external files
    dir = File.expand_path('../../', __FILE__)
    files = Dir.glob( "#{dir}/app/controllers/sessions/collection_*.rb" )
    files.each { |file|
      load file
      (default_collection, assets ) = ExtraCollection.session( default_collection, assets, user )
    }

    [default_collection, assets]
  end

  def self.models(user = nil)
    models = {}
    objects = ObjectManager.list_objects
    objects.each {|object|
      attributes = ObjectManager::Attribute.by_object(object, user)
      models[object] = attributes
    }
    models
  end

  def self.cleanup_expired

    # delete temp. sessions
    ActiveRecord::SessionStore::Session.where('persistent IS NULL AND updated_at < ?', Time.zone.now - 1.days ).delete_all

    # web sessions older the x days
    ActiveRecord::SessionStore::Session.where('updated_at < ?', Time.zone.now - 90.days ).delete_all

  end

  def self.get(id)
    ActiveRecord::SessionStore::Session.where( id: id ).first
  end

  def self.list(limit = 10_000)
    ActiveRecord::SessionStore::Session.order('updated_at DESC').limit(limit)
  end

  def self.destroy(id)
    session = ActiveRecord::SessionStore::Session.where( id: id ).first
    return if !session
    session.destroy
  end
end
