class UpdateObjectManager3 < ActiveRecord::Migration
  def up

    ObjectManager::Attribute.add(
      :object     => 'User',
      :name       => 'login',
      :display    => 'Login',
      :data_type  => 'input',
      :data_option => {
        :type      => 'text',
        :maxlength => 100,
        :null      => true,
        :autocapitalize => false,
      },
      :editable           => false,
      :active             => true,
      :screens            => {
        :signup => {},
        :invite_agent => {},
        :edit => {},
      },
      :pending_migration  => false,
      :position           => 100,
      :created_by_id      => 1,
      :updated_by_id      => 1,
    )

  end

  def down
  end
end
