# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AgendBasedSenderIssue1351 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    EmailAddress.all.each do |email_address|

      email_address.save!
    rescue => e
      Rails.logger.error "Unable to update EmailAddress.find(#{email_address.id}) '#{email_address.inspect}': #{e.message}"

    end
  end
end
