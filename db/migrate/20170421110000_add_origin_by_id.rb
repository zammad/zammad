class AddOriginById < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :ticket_articles, :origin_by_id, :integer
  end
end
