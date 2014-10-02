class UpdateObjectManager4 < ActiveRecord::Migration
  def up

    ObjectManager::Attribute.add(
      :object     => 'TicketArticle',
      :name       => 'body',
      :display    => 'Text',
      :data_type  => 'richtext',
      :data_option => {
        :type      => 'textonly',
        :maxlength => 20000,
        :upload    => true,
        :rows      => 8,
        :null      => true,
      },
      :editable           => false,
      :active             => true,
      :screens            => {
        :create_top => {
          '-all-' => {
            :null => false,
          },
        },
        :edit => {
          :Agent => {
            :null => true,
          },
          :Customer => {
            :null => false,
          },
        },
      },
      :pending_migration  => false,
      :position           => 600,
      :created_by_id      => 1,
      :updated_by_id      => 1,
    )

  end

  def down
  end
end
