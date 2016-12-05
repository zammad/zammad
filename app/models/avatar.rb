# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Avatar < ApplicationModel
  belongs_to :object_lookup,   class_name: 'ObjectLookup'

=begin

add an avatar based on auto detection (email address)

  Avatar.auto_detection(
    object: 'User',
    o_id: user.id,
    url: 'somebody@example.com',
    updated_by_id: 1,
    created_by_id: 1,
  )

=end

  def self.auto_detection(data)

    # return if we run import mode
    return if Setting.get('import_mode')
    return if data[:url].blank?

    Avatar.add(
      object: data[:object],
      o_id: data[:o_id],
      url: data[:url],
      source: 'zammad.com',
      deletable: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

=begin

add avatar by upload

  Avatar.add(
    object: 'User',
    o_id: user.id,
    default: true,
    full: {
      content: '...',
      mime_type: 'image/png',
    },
    resize: {
      content: '...',
      mime_type: 'image/png',
    },
    source: 'web',
    deletable: true,
    updated_by_id: 1,
    created_by_id: 1,
  )

add avatar by url

  Avatar.add(
    object: 'User',
    o_id: user.id,
    default: true,
    url: ...,
    source: 'web',
    deletable: true,
    updated_by_id: 1,
    created_by_id: 1,
  )

=end

  def self.add(data)

    # lookups
    if data[:object]
      object_id = ObjectLookup.by_name(data[:object])
    end

    # add initial avatar
    add_init_avatar(object_id, data[:o_id])

    record = {
      o_id: data[:o_id],
      object_lookup_id: object_id,
      default: true,
      deletable: data[:deletable],
      initial: false,
      source: data[:source],
      source_url: data[:url],
      updated_by_id: data[:updated_by_id],
      created_by_id: data[:created_by_id],
    }

    # check if avatar with url already exists
    avatar_already_exists = nil
    if data[:source].present?
      avatar_already_exists = Avatar.find_by(
        object_lookup_id: object_id,
        o_id: data[:o_id],
        source: data[:source],
      )
    end

    # fetch image based on http url
    if data[:url] =~ /^http/

      # check if source ist already updated within last 2 minutes
      if avatar_already_exists && avatar_already_exists.source_url == data[:url]
        return if avatar_already_exists.updated_at > 2.minutes.ago
      end

      # twitter workaround to get bigger avatar images
      # see also https://dev.twitter.com/overview/general/user-profile-images-and-banners
      if data[:url] =~ %r{//pbs.twimg.com/}i
        data[:url].sub!(/normal\.(png|jpg|gif)$/, 'bigger.\1')
      end

      # fetch image
      response = UserAgent.get(
        data[:url],
        {},
        {
          open_timeout: 4,
          read_timeout: 6,
          total_timeout: 6,
        },
      )
      if !response.success?
        logger.info "Can't fetch '#{data[:url]}' (maybe no avatar available), http code: #{response.code}"
        return
      end
      logger.info "Fetchd image '#{data[:url]}', http code: #{response.code}"
      mime_type = 'image'
      if data[:url] =~ /\.png/i
        mime_type = 'image/png'
      end
      if data[:url] =~ /\.(jpg|jpeg)/i
        mime_type = 'image/jpeg'
      end
      if !data[:resize]
        data[:resize] = {}
      end
      data[:resize][:content] = response.body
      data[:resize][:mime_type] = mime_type
      if !data[:full]
        data[:full] = {}
      end
      data[:full][:content] = response.body
      data[:full][:mime_type] = mime_type

    # try zammad backend to find image based on email
    elsif data[:url] && data[:url] =~ /@/

      # check if source ist already updated within last 3 minutes
      if avatar_already_exists && avatar_already_exists.source_url == data[:url]
        return if avatar_already_exists.updated_at > 2.minutes.ago
      end

      # fetch image
      image = Service::Image.user(data[:url])
      return if !image
      if !data[:resize]
        data[:resize] = {}
      end
      data[:resize] = image
      if !data[:full]
        data[:full] = {}
      end
      data[:full] = image
    end

    # check if avatar need to be updated
    record[:store_hash] = Digest::MD5.hexdigest(data[:resize][:content])
    if avatar_already_exists && avatar_already_exists.store_hash == record[:store_hash]
      avatar_already_exists.touch
      return avatar_already_exists
    end

    # store images
    object_name = "Avatar::#{data[:object]}"
    if data[:full]
      store_full = Store.add(
        object: "#{object_name}::Full",
        o_id: data[:o_id],
        data: data[:full][:content],
        filename: 'avatar_full',
        preferences: {
          'Mime-Type' => data[:full][:mime_type]
        },
        created_by_id: data[:created_by_id],
      )
      record[:store_full_id] = store_full.id
      record[:store_hash]    = Digest::MD5.hexdigest(data[:full][:content])
    end
    if data[:resize]
      store_resize = Store.add(
        object: "#{object_name}::Resize",
        o_id: data[:o_id],
        data: data[:resize][:content],
        filename: 'avatar',
        preferences: {
          'Mime-Type' => data[:resize][:mime_type]
        },
        created_by_id: data[:created_by_id],
      )
      record[:store_resize_id] = store_resize.id
      record[:store_hash]      = Digest::MD5.hexdigest(data[:resize][:content] )
    end

    # update existing
    if avatar_already_exists
      avatar_already_exists.update_attributes(record)
      avatar = avatar_already_exists

    # add new one and set it as default
    else
      avatar = Avatar.create(record)
      set_default_items(object_id, data[:o_id], avatar.id)
    end

    avatar
  end

=begin

set avatars as default

  Avatar.set_default('User', 123, avatar_id)

=end

  def self.set_default(object_name, o_id, avatar_id)
    object_id = ObjectLookup.by_name(object_name)
    avatar = Avatar.find_by(
      object_lookup_id: object_id,
      o_id: o_id,
      id: avatar_id,
    )
    avatar.default = true
    avatar.save!

    # set all other to default false
    set_default_items(object_id, o_id, avatar_id)

    avatar
  end

=begin

remove all avatars of an object

  Avatar.remove('User', 123)

=end

  def self.remove(object_name, o_id)
    object_id = ObjectLookup.by_name(object_name)
    Avatar.where(
      object_lookup_id: object_id,
      o_id: o_id,
    ).destroy_all

    object_name_store = "Avatar::#{object_name}"
    Store.remove(
      object: "#{object_name_store}::Full",
      o_id: o_id,
    )
    Store.remove(
      object: "#{object_name_store}::Resize",
      o_id: o_id,
    )
  end

=begin

remove one avatars of an object

  Avatar.remove_one('User', 123, avatar_id)

=end

  def self.remove_one(object_name, o_id, avatar_id)
    object_id = ObjectLookup.by_name(object_name)
    Avatar.where(
      object_lookup_id: object_id,
      o_id: o_id,
      id: avatar_id,
    ).destroy_all
  end

=begin

return all avatars of an user

  avatars = Avatar.list('User', 123)

=end

  def self.list(object_name, o_id)
    object_id = ObjectLookup.by_name(object_name)
    avatars = Avatar.where(
      object_lookup_id: object_id,
      o_id: o_id,
    ).order('initial DESC, deletable ASC, created_at ASC, id DESC')

    # add initial avatar
    add_init_avatar(object_id, o_id)

    avatar_list = []
    avatars.each do |avatar|
      data = avatar.attributes
      if avatar.store_resize_id
        file            = Store.find(avatar.store_resize_id)
        data['content'] = "data:#{file.preferences['Mime-Type']};base64,#{Base64.strict_encode64(file.content)}"
      end
      avatar_list.push data
    end
    avatar_list
  end

=begin

get default avatar image of user by hash

  store = Avatar.get_by_hash(hash)

returns:

  store object

=end

  def self.get_by_hash(hash)
    avatar = Avatar.find_by(
      store_hash: hash,
    )
    return if !avatar
    file = Store.find(avatar.store_resize_id)
  end

=begin

get default avatar of user by user id

  avatar = Avatar.get_default('User', user_id)

returns:

  avatar object

=end

  def self.get_default(object_name, o_id)
    object_id = ObjectLookup.by_name(object_name)
    Avatar.find_by(
      object_lookup_id: object_id,
      o_id: o_id,
      default: true,
    )
  end

  def self.set_default_items(object_id, o_id, avatar_id)
    avatars = Avatar.where(
      object_lookup_id: object_id,
      o_id: o_id,
    ).order('created_at ASC, id DESC')
    avatars.each do |avatar|
      next if avatar.id == avatar_id
      avatar.default = false
      avatar.save!
    end
  end

  def self.add_init_avatar(object_id, o_id)

    count = Avatar.where(
      object_lookup_id: object_id,
      o_id: o_id,
    ).count
    return if count.positive?

    Avatar.create(
      o_id: o_id,
      object_lookup_id: object_id,
      default: true,
      source: 'init',
      initial: true,
      deletable: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
