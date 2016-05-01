class UpdateCti < ActiveRecord::Migration
  def up
    setting = Setting.find_by(name: 'sipgate_integration')
    if setting
      setting.preferences = { prio: 1, trigger: 'cti:reload' }
      setting.save
    end

    setting = Setting.find_by(name: 'chat')
    if setting
      setting.preferences = { trigger: ['menu:render', 'chat:rerender'] }
      setting.save
    end
  end
end
