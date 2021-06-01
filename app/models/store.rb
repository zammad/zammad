# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'store/object'
require_dependency 'store/file'

class Store < ApplicationModel
  PREFERENCES_SIZE_MAX = 2400

  belongs_to :store_object, class_name: 'Store::Object', optional: true
  belongs_to :store_file,   class_name: 'Store::File', optional: true

  validates :filename, presence: true

  store :preferences

  before_create :oversized_preferences_check
  after_create :generate_previews
  before_update :oversized_preferences_check

=begin

add an attachment to storage

  result = Store.add(
    object: 'Ticket::Article',
    o_id: 4711,
    data: binary_string,
    filename: 'filename.txt',
    preferences: {
      content_type: 'image/png',
      content_id: 234,
    }
  )

returns

  result = true

=end

  def self.add(data)
    data.deep_stringify_keys!

    # lookup store_object.id
    store_object = Store::Object.create_if_not_exists(name: data['object'])
    data['store_object_id'] = store_object.id

    # add to real store
    file = Store::File.add(data['data'])

    data['size'] = data['data'].to_s.bytesize
    data['store_file_id'] = file.id

    # not needed attributes
    data.delete('data')
    data.delete('object')

    Store.create!(data)
  end

=begin

get attachment of object

  list = Store.list(
    object: 'Ticket::Article',
    o_id: 4711,
  )

returns

  result = [store1, store2]

  store1 = {
    size: 94123,
    filename: 'image.png',
    preferences: {
      content_type: 'image/png',
      content_id: 234,
    }
  }
  store1.content # binary_string

=end

  def self.list(data)
    # search
    store_object_id = Store::Object.lookup(name: data[:object])
    Store.where(store_object_id: store_object_id, o_id: data[:o_id].to_i)
                  .order(created_at: :asc)

  end

=begin

remove attachments of object from storage

  result = Store.remove(
    object: 'Ticket::Article',
    o_id: 4711,
  )

returns

  result = true

=end

  def self.remove(data)
    # search
    store_object_id = Store::Object.lookup(name: data[:object])
    stores = Store.where(store_object_id: store_object_id)
                  .where(o_id: data[:o_id])
                  .order(created_at: :asc)
    stores.each do |store|

      # check backend for references
      Store.remove_item(store.id)
    end
    true
  end

=begin

remove one attachment from storage

  Store.remove_item(store_id)

=end

  def self.remove_item(store_id)
    store   = Store.find(store_id)
    file_id = store.store_file_id

    # check backend for references
    files = Store.where(store_file_id: file_id)
    if files.count > 1 || files.first.id != store.id
      store.destroy!
      return true
    end

    store.destroy!
    Store::File.find(file_id).destroy!
  end

=begin

get content of file

  store = Store.find(store_id)
  content_as_string = store.content

returns

  content_as_string

=end

  def content
    file = Store::File.find_by(id: store_file_id)
    if !file
      raise "No such file #{store_file_id}!"
    end

    file.content
  end

=begin

get content of file in preview size

  store = Store.find(store_id)
  content_as_string = store.content_preview

returns

  content_as_string

=end

  def content_preview(options = {})
    file = Store::File.find_by(id: store_file_id)
    if !file
      raise "No such file #{store_file_id}!"
    end
    raise 'Unable to generate preview' if options[:silence] != true && preferences[:content_preview] != true

    image_resize(file.content, 200)
  end

=begin

get content of file in inline size

  store = Store.find(store_id)
  content_as_string = store.content_inline

returns

  content_as_string

=end

  def content_inline(options = {})
    file = Store::File.find_by(id: store_file_id)
    if !file
      raise "No such file #{store_file_id}!"
    end
    raise 'Unable to generate inline' if options[:silence] != true && preferences[:content_inline] != true

    image_resize(file.content, 1800)
  end

=begin

get content of file

  store = Store.find(store_id)
  location_of_file = store.save_to_file

returns

  location_of_file

=end

  def save_to_file(path = nil)
    content
    file = Store::File.find_by(id: store_file_id)
    if !file
      raise "No such file #{store_file_id}!"
    end

    if !path
      path = Rails.root.join('tmp', filename)
    end
    ::File.open(path, 'wb') do |handle|
      handle.write file.content
    end
    path
  end

  def attributes_for_display
    slice :id, :filename, :size, :preferences
  end

  def provider
    file = Store::File.find_by(id: store_file_id)
    if !file
      raise "No such file #{store_file_id}!"
    end

    file.provider
  end

  RESIZABLE_MIME_REGEXP = %r{image/(jpeg|jpg|png)}i.freeze

  def self.resizable_mime?(input)
    input.match? RESIZABLE_MIME_REGEXP
  end

  private

  def generate_previews
    return true if Setting.get('import_mode')

    resizable = preferences
                  .slice('Mime-Type', 'Content-Type', 'mime_type', 'content_type')
                  .values
                  .any? { |mime| self.class.resizable_mime?(mime) }

    begin
      if resizable
        if content_preview(silence: true)
          preferences[:resizable] = true
          preferences[:content_preview] = true
        end
        if content_inline(silence: true)
          preferences[:resizable] = true
          preferences[:content_inline] = true
        end
        if preferences[:resizable]
          save!
        end
      end
    rescue => e
      logger.error e
      preferences[:resizable] = false
      save!
    end
  end

  def image_resize(content, width)
    local_sha = Digest::SHA256.hexdigest(content)

    cache_key = "image-resize-#{local_sha}_#{width}"
    image = Cache.read(cache_key)
    return image if image

    temp_file = ::Tempfile.new
    temp_file.binmode
    temp_file.write(content)
    temp_file.close
    image = Rszr::Image.load(temp_file.path)

    # do not resize image if image is smaller or already same size
    return if image.width <= width

    # do not resize image if new height is smaller then 7px (images
    # with small height are usually useful to resize)
    ratio = image.width / width
    return if image.height / ratio <= 6

    image.resize!(width, :auto)
    temp_file_resize = ::Tempfile.new.path
    image.save(temp_file_resize)
    image_resized = ::File.binread(temp_file_resize)

    Cache.write(cache_key, image_resized, { expires_in: 6.months })

    image_resized
  end

  def oversized_preferences_check
    [[600, 100], [300, 60], [150, 30], [75, 15]].each do |row|
      return true if oversized_preferences_removed_by_content?(row[0])
      return true if oversized_preferences_removed_by_key?(row[1])
    end

    true
  end

  def oversized_preferences_removed_by_content?(max_char)
    oversized_preferences_removed? do |_key, content|
      content.try(:size).to_i > max_char
    end
  end

  def oversized_preferences_removed_by_key?(max_char)
    oversized_preferences_removed? do |key, _content|
      key.try(:size).to_i > max_char
    end
  end

  def oversized_preferences_removed?
    return true if !oversized_preferences_present?

    preferences&.each do |key, content|
      next if !yield(key, content)

      preferences.delete(key)
      Rails.logger.info "Removed oversized #{self.class.name} preference: '#{key}', '#{content}'"

      break if !oversized_preferences_present?
    end

    !oversized_preferences_present?
  end

  def oversized_preferences_present?
    preferences.to_yaml.size > PREFERENCES_SIZE_MAX
  end
end
