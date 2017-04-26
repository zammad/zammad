class AddReplyTo < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :ticket_articles, :reply_to, :string, limit: 3000
  end
end
