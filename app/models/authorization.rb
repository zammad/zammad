# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Authorization < ApplicationModel
  belongs_to    :user
  after_create  :delete_user_cache
  after_update  :delete_user_cache
  after_destroy :delete_user_cache
  validates     :user_id,  presence: true
  validates     :uid,      presence: true, uniqueness: { scope: :provider }
  validates     :provider, presence: true

  def self.find_from_hash(hash)
    auth = Authorization.find_by(provider: hash['provider'], uid: hash['uid'])
    if auth

      # update auth tokens
      auth.update_attributes(
        token: hash['credentials']['token'],
        secret: hash['credentials']['secret']
      )

      # update username of auth entry if empty
      if !auth.username && hash['info']['nickname']
        auth.update_attributes(
          username: hash['info']['nickname'],
        )
      end

      # update image if needed
      if hash['info']['image']
        user = User.find(auth.user_id)

        # save/update avatar
        avatar = Avatar.add(
          object: 'User',
          o_id: user.id,
          url: hash['info']['image'],
          source: hash['provider'],
          deletable: true,
          updated_by_id: user.id,
          created_by_id: user.id,
        )

        # update user link
        if avatar && user.image != avatar.store_hash
          user.image = avatar.store_hash
          user.save
        end
      end
    end
    auth
  end

  def self.create_from_hash(hash, user = nil)

    if !user
      user = User.create_from_hash!(hash)
    end

    # save/update avatar
    if hash['info']['image']
      avatar = Avatar.add(
        object: 'User',
        o_id: user.id,
        url: hash['info']['image'],
        source: hash['provider'],
        deletable: true,
        updated_by_id: user.id,
        created_by_id: user.id,
      )

      # update user link
      if avatar && user.image != avatar.store_hash
        user.image = avatar.store_hash
        user.save
      end
    end

    Authorization.create(
      user: user,
      uid: hash['uid'],
      username: hash['info']['nickname'] || hash['info']['username'] || hash['info']['name'] || hash['info']['email'] || hash['username'],
      provider: hash['provider'],
      token: hash['credentials']['token'],
      secret: hash['credentials']['secret']
    )
  end

  private

  def delete_user_cache
    return if !user
    user.touch
  end

end
