module SessionHelper
  def self.default_collections

    # auto population collections, store all here
    default_collection = {}

    # load collections to deliver from external files
    dir = File.expand_path('../../', __FILE__)
    files = Dir.glob( "#{dir}/app/controllers/sessions/collection_*.rb" )
    for file in files
      load file
      ExtraCollection.session(default_collection)
    end

    return default_collection
  end
  def self.push_collections

    # auto population collections, store all here
    push_collections = {}

    # load collections to deliver from external files
    dir = File.expand_path('../../', __FILE__)
    files = Dir.glob( "#{dir}/app/controllers/sessions/collection_*.rb" )
    for file in files
      load file
      ExtraCollection.push(push_collections)
    end

    return push_collections
  end
end