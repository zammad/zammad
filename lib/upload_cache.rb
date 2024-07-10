# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
    @id = id
  end

  # Adds a Store item with the given attributes for the form_id.
  #
  # @see Store#create!
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
    Store.create!(
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

  # Checks if files list includes a similar looking store attachment.
  # Similar-looking attachment is detected by name and file type if it is present.
  #
  # @param files [Array<Hash>] list of hashes with name and type keys.
  # @param single_attachment [Store] a Store object or a similar-looking hash.
  #
  # @see Store.check_attachment_match
  def self.files_include_attachment?(files, single_attachment)
    files.any? { |elem| attachment_matches?(single_attachment, elem) }
  end

  private

  def store_object
    self.class.name
  end

  def store_object_id
    Store::Object.lookup(name: store_object).id
  end

  # Checks if attachment is similar to the given file.
  #
  # @param attachment [Store] with filename key and preferences hash with Content-Type key.
  # @param file [Hash] with name and type keys.
  def self.attachment_matches?(attachment, file)
    return false if file[:name] != attachment.filename

    attachment_content_type = attachment.preferences['Content-Type']
    if file[:type].blank? || attachment_content_type.blank?
      return true
    end

    file[:type] == attachment_content_type
  end
  private_class_method :attachment_matches?
end
