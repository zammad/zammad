
class ContenteditableIamges < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    change_column :text_modules, :content, :text, limit: 10.megabytes + 1, null: false
    change_column :signatures, :body, :text, limit: 10.megabytes + 1, null: true
    change_column :ticket_articles, :body, :text, limit: 20.megabytes + 1, null: false
  end
end
