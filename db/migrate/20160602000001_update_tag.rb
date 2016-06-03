class UpdateTag < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    remove_index :tag_items, column: [:name]
    add_column :tag_items, :name_downcase, :string, limit: 250
    add_index :tag_items, [:name_downcase]
    Tag.reset_column_information
    Tag::Item.all.each(&:save)

    Setting.create_if_not_exists(
      title: 'New Tags',
      name: 'tag_new',
      area: 'Web::Base',
      description: 'Allow users to crate new tags.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'tag_new',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: true,
      frontend: true,
    )
  end
end
