# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3669FixDomain < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    Channel.where(area: ['Google::Account', 'Microsoft365::Account']).each do |channel|
      channel.options[:outbound][:options].delete(:domain)
      channel.save!
    end
  end
end
