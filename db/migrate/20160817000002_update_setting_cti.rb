class UpdateSettingCti < ActiveRecord::Migration
  def up
    setting = Setting.find_by(name: 'sipgate_integration')
    setting.frontend = true
    setting.preferences[:authentication] = true
    setting.save!

    %w(system_id ticket_hook customer_ticket_create customer_ticket_create_group_ids customer_ticket_view models_searchable tag_new defaults_calendar_subscriptions_tickets).each { |name|
      setting = Setting.find_by(name: name)
      setting.preferences[:authentication] = true
      setting.save!
    }
  end
end
