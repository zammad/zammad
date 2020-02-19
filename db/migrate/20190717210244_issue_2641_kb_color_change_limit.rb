class Issue2641KbColorChangeLimit < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.find_by(name: 'system_init_done')

    change_column :knowledge_bases, :color_highlight, :string, limit: 25
    change_column :knowledge_bases, :color_header,    :string, limit: 25
  end
end
