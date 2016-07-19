
class UpdateCalendars < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    change_column :calendars, :business_hours, :string, limit: 3000, null: true
  end
end
