
class TemplateUpdate < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    change_column :templates, :options, :text, limit: 10.megabytes + 1, null: true
  end
end
