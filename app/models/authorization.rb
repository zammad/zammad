# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Authorization < ApplicationModel
  belongs_to    :user, optional: true
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
      auth.update!(
        token:  hash['credentials']['token'],
        secret: hash['credentials']['secret']
      )

      # update username of auth entry if empty
      if !auth.username && hash['info']['nickname'].present?
        auth.update!(
          username: hash['info']['nickname'],
        )
      end

      # update firstname/lastname if needed
      user = User.find(auth.user_id)
      if user.firstname.blank? && user.lastname.blank?
        if hash['info']['first_name'].present? && hash['info']['last_name'].present?
          user.firstname = hash['info']['first_name']
          user.lastname = hash['info']['last_name']
        elsif hash['info']['display_name'].present?
          user.firstname = hash['info']['display_name']
        end
      end

      # update image if needed
      if hash['info']['image'].present?
        avatar = Avatar.add(
          object:        'User',
          o_id:          user.id,
          url:           hash['info']['image'],
          source:        hash['provider'],
          deletable:     true,
          updated_by_id: user.id,
          created_by_id: user.id,
        )
        if avatar && user.image != avatar.store_hash
          user.image = avatar.store_hash
        end
      end

      if user.changed?
        user.save
      end
    end
    auth
  end

  def self.create_from_hash(hash, user = nil)

    if !user && Setting.get('auth_third_party_auto_link_at_inital_login') && hash['info'] && hash['info']['email'].present?
      user = User.find_by(email: hash['info']['email'].downcase)
    end

    if !user
      user = User.create_from_hash!(hash)
    end

    # save/update avatar
    if hash['info'].present? && hash['info']['image'].present?
      avatar = Avatar.add(
        object:        'User',
        o_id:          user.id,
        url:           hash['info']['image'],
        source:        hash['provider'],
        deletable:     true,
        updated_by_id: user.id,
        created_by_id: user.id,
      )

      # update user link
      if avatar && user.image != avatar.store_hash
        user.image = avatar.store_hash
        user.save
      end
    end

    Authorization.create!(
      user:     user,
      uid:      hash['uid'],
      username: hash['info']['nickname'] || hash['info']['username'] || hash['info']['name'] || hash['info']['email'] || hash['username'],
      provider: hash['provider'],
      token:    hash['credentials']['token'],
      secret:   hash['credentials']['secret']
    )
  end

  private

  def delete_user_cache
    return if !user

    user.touch # rubocop:disable Rails/SkipsModelValidations
  end

end
