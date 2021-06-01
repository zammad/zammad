# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AgentCustomerPermission < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.where(name: ['ticket.agent', 'ticket.customer', 'chat.agent', 'cti.agent']).each do |permission|
      permission.preferences.delete(:not)
      permission.save!
    end
  end
end
