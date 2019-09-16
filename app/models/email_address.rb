# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class EmailAddress < ApplicationModel
  include ChecksLatestChangeObserved

  has_many        :groups,   after_add: :cache_update, after_remove: :cache_update
  belongs_to      :channel, optional: true
  validates       :realname, presence: true
  validates       :email,    presence: true

  before_validation :check_email
  before_create   :check_if_channel_exists_set_inactive
  before_update   :check_if_channel_exists_set_inactive
  after_create    :update_email_address_id
  after_update    :update_email_address_id
  before_destroy  :delete_group_reference

=begin

check and if channel not exists reset configured channels for email addresses

  EmailAddress.channel_cleanup

=end

  def self.channel_cleanup
    EmailAddress.all.each do |email_address|

      # set to active if channel exists
      if email_address.channel_id && Channel.find_by(id: email_address.channel_id)
        if !email_address.active
          email_address.save!
        end
        next
      end

      # set in inactive if channel not longer exists
      next if !email_address.active

      email_address.save!
    end
  end

  private

  def check_email
    return true if Setting.get('import_mode')
    return true if email.blank?

    self.email = email.downcase.strip
    raise Exceptions::UnprocessableEntity, 'Invalid email' if !email.match?(/@/)
    raise Exceptions::UnprocessableEntity, 'Invalid email' if email.match?(/\s/)

    true
  end

  # set email address to inactive/active if channel exists or not
  def check_if_channel_exists_set_inactive

    # set to active if channel exists
    if channel_id && Channel.find_by(id: channel_id)
      self.active = true
      return true
    end

    # set in inactive if channel not longer exists
    self.channel_id = nil
    self.active = false
    true
  end

  # delete group.email_address_id reference if email address get's deleted
  def delete_group_reference
    Group.where(email_address_id: id).each do |group|
      group.update!(email_address_id: nil)
    end
  end

  # keep email email address is of initial group filled
  def update_email_address_id
    not_configured = Group.where(email_address_id: nil).count
    total = Group.count
    return if not_configured.zero?
    return if total != 1

    group = Group.find_by(email_address_id: nil)
    group.email_address_id = id
    group.updated_by_id = updated_by_id
    group.save!
  end

end
