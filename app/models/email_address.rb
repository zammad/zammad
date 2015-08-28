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
      next if !email_address.channel_id
      next if Channel.find_by(id: email_address.channel_id)
      email_address.channel_id = nil
      email_address.save
    }
  end

  private

  def channel_check
    return if Channel.find_by(id: channel_id)
    self.channel_id = nil
  end

end
