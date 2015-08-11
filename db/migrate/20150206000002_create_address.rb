class CreateAddress < ActiveRecord::Migration
  def up
    add_column :users, :address,  :string,  limit: 500, null: true

    User.all.each {|user|
      address = ''
      if user.street && !user.street.empty?
        address += "#{user.street}\n"
      end
      if user.zip && !user.zip.empty?
        address += "#{user.zip} "
      end
      if user.city && !user.city.empty?
        address += "#{user.city}"
      end
      if !address.empty?
        user.address = address
        user.save
      end
    }

    %w(street zip city department).each {|attribute_name|
      attribute = ObjectManager::Attribute.get(
        object: 'User',
        name: attribute_name,
      )
      if attribute
        attribute.active = false
        attribute.save
      end
    }

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'address',
      display: 'Address',
      data_type: 'textarea',
      data_option: {
        type: 'text',
        maxlength: 500,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 1350,
      created_by_id: 1,
      updated_by_id: 1,
    )

  end

  def down
  end
end
