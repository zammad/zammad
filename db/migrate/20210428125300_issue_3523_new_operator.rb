# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3523NewOperator < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    overview = Overview.find_by(link: 'all_escalated')
    return if !overview
    return if overview.condition['ticket.escalation_at'].blank?
    return if overview.condition['ticket.escalation_at'][:operator] != 'before (relative)'

    overview.condition['ticket.escalation_at'][:operator] = 'till (relative)'
    overview.save!
  end
end
