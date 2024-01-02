# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Issue4848FixOverviewBulkScreen < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.for_object('Ticket').where(name: %w[state_id pending_time group_id owner_id priority_id]).each do |field|
      field.screens[:overview_bulk] = {
        'ticket.agent' => overview_bulk_configs[field.name],
      }
      field.save!
    end
  end

  def overview_bulk_configs
    @overview_bulk_configs ||= {
      'state_id'     => {
        nulloption: true,
        null:       true,
        default:    '',
        filter:     Ticket::State.by_category(:viewable_agent_edit).pluck(:id),
      },
      'pending_time' => {
        nulloption:    true,
        null:          true,
        default:       '',
        orientation:   'top',
        disableScroll: true,
      },
      'group_id'     => {
        nulloption: true,
        null:       true,
        default:    '',
        direction:  'up',
      },
      'owner_id'     => {
        nulloption: true,
        null:       true,
        default:    '',
      },
      'priority_id'  => {
        nulloption: true,
        null:       true,
        default:    '',
      },
    }
  end
end
