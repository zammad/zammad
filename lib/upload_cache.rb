# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# A wrapper class around Store that handles temporary attachment uploads
# and provides an interface for those.
class UploadCache

  attr_reader :id

  # Initializes a UploadCache for a given form_id.
  #
  # @example
  #   cache = UploadCache.new(form_id)
  #
  # @return [UploadCache]
  def initialize(id)
    # conversion to Integer is required for proper Store#o_id comparsion
    @id = id.to_i
  end

  # Adds a Store item with the given attributes for the form_id.
  #
  # @see Store#add
  #
  # @example
  #   cache = UploadCache.new(form_id)
  #   store = cache.add(
  #     filename:    file.original_filename,
  #     data:        file.read,
  #     preferences: {
  #       'Content-Type' => 'application/octet-stream'
  #     }
  #   )
  #
  # @return [Store] the created Store item
  def add(args)
    Store.add(
      args.merge(
        object: store_object,
        o_id:   id,
      )
    )
  end

  # Provides all Store items associated to the form_id.
  #
  # @see Store#list
  #
  # @example
  #   attachments = UploadCache.new(form_id).attachments
  #
  # @return [Array<Store>] an enumerator of Store items
  def attachments
    Store.list(
      object: store_object,
      o_id:   id,
    )
  end

  # Removes all Store items associated to the form_id.
  #
  # @see Store#remove
  #
  # @example
  #   UploadCache.new(form_id).destroy
  #
  def destroy
    Store.remove(
      object: store_object,
      o_id:   id,
    )
  end

  # Removes all Store items associated to the form_id.
  #
  # @see Store#remove
  #
  # @example
  #   UploadCache.new(form_id).remove_item(store_id)
  #
  # @raise [Exceptions::UnprocessableEntity] in cases where a Store item should get deleted that is not an UploadCache item
  #
  def remove_item(store_id = nil)
    store = Store.find(store_id)
    if store.o_id != id || store.store_object_id != store_object_id
      raise Exceptions::UnprocessableEntity, "Attempt to delete Store item #{store_id} that is not bound to UploadCache object"
    end

    Store.remove_item(store_id)
  end

  private

  def store_object
    self.class.name
  end

  def store_object_id
    Store::Object.lookup(name: store_object).id
  end
end
