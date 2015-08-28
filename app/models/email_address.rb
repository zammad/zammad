# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class EmailAddress < ApplicationModel
  has_many        :groups,   after_add: :cache_update, after_remove: :cache_update
  belongs_to      :channel
  validates       :realname, presence: true
  validates       :email,    presence: true

  before_create   :channel_check
  before_update   :channel_check

  latest_change_support

=begin

check and if channel not exists reset configured channels for email addresses

  EmailAddress.channel_cleanup

=end

  def self.channel_cleanup
    EmailAddress.all.each {|email_address|
      if email_address.channel_id && Channel.find_by(id: email_address.channel_id)
        if !email_address.active
          email_address.save
        end
        next
      end
      if email_address.channel_id || email_address.active
        email_address.save
      end
    }
  end

  private

  def channel_check
    if channel_id && Channel.find_by(id: channel_id)
      self.active = true
      return true
    end
    self.channel_id = nil
    self.active = false
    true
  end

end
