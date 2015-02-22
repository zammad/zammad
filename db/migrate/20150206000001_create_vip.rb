class CreateVip < ActiveRecord::Migration
  def up
    add_column :users, :vip,  :boolean,  :default => false

    ObjectManager::Attribute.add(
      :object      => 'User',
      :name        => 'vip',
      :display     => 'VIP',
      :data_type   => 'boolean',
      :data_option => {
        :null       => true,
        :default    => false,
        :item_class => 'formGroup--halfSize',
        :options    => {
          :false => 'no',
          :true  => 'yes',
        },
        :translate => true,
      },
      :editable => false,
      :active   => true,
      :screens  => {
        :edit => {
          :Admin => {
            :null => true,
          },
          :Agent => {
            :null => true,
          },
        },
        :view => {
          '-all-' => {
            :shown => false,
          },
        },
      },
      :pending_migration => false,
      :position          => 1490,
      :created_by_id     => 1,
      :updated_by_id     => 1,
    )

  end

  def down
  end
end
