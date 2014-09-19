class UpdateObjectManager2 < ActiveRecord::Migration
  def up

    ObjectManager::Attribute.add(
      :object     => 'Ticket',
      :name       => 'customer_id',
      :display    => 'Customer',
      :data_type  => 'user_autocompletion',
      :data_option => {
        :autocapitalize => false,
        :multiple     => false,
        :null         => false,
        :limit        => 200,
        :placeholder  => 'Enter Person or Organisation/Company',
        :minLengt     => 2,
        :translate    => false,
      },
      :editable           => false,
      :active             => true,
      :screens            => {
        :create_top => {
          :Agent => {
            :null => false,
          },
        },
        :edit => {},
      },
      :pending_migration  => false,
      :position           => 10,
      :created_by_id      => 1,
      :updated_by_id      => 1,
    )

  end

  def down
  end
end
