# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2019FixDoubleDomainLinksInTriggerEmails < ActiveRecord::Migration[5.1]
  DOUBLE_DOMAIN_REGEX = %r{(?<=<a href=")https?://[^"]+(?=(https?|\#{config\.http_type})://.+?".*?>)}.freeze

  def up
    return if !Setting.exists?(name: 'system_init_done')

    Trigger.where('perform LIKE ?', '%notification.email: %')
           .find_each do |t|
             email_response = t.perform['notification.email']
             next if email_response.blank? || !email_response['body']&.match(DOUBLE_DOMAIN_REGEX)

             email_response['body'] = email_response['body'].gsub(DOUBLE_DOMAIN_REGEX, '')
             next if !t.perform_changed?

             t.save
           end
  end
end
