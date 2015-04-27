module AutoWizard

=begin

creates or updates Users, EmailAddresses and sets Settings based on the 'auto_wizard.json' file placed in the root directory.

there is an example file 'contrib/auto_wizard_example.json'

  AutoWizard.setup

returns

  the first created User if a 'auto_wizard.json' file was found and processed, containing at least one entry in Users

  the User with id 1 (NULL) if a 'auto_wizard.json' file was found and processed, containing no Users

  nil if no 'auto_wizard.json' file was found

=end

  def self.setup

    auto_wizard_file_name = 'auto_wizard.json'
    auto_wizard_file_name = "#{Rails.root.to_s}/#{auto_wizard_file_name}"

    return if !File.file?(auto_wizard_file_name)

    auto_wizard_file = File.read(auto_wizard_file_name)

    auto_wizard_hash = JSON.parse(auto_wizard_file)

    admin_user = User.find( 1 )

    # create Users
    if auto_wizard_hash['Users']

      roles  = Role.where( name: ['Agent', 'Admin'] )
      groups = Group.all

      auto_wizard_hash['Users'].each { |user_data|

        user_data_symbolized = user_data.symbolize_keys

        user_data_symbolized = user_data_symbolized.merge(
          {
            active: true,
            roles: roles,
            groups: groups,
            updated_by_id: admin_user.id,
            created_by_id: admin_user.id
          }
        )

        created_user = User.create_or_update(
          user_data_symbolized
        )

        # use first created user as admin
        next if admin_user.id != 1

        admin_user = created_user
      }
    end

    # set Settings
    if auto_wizard_hash['Settings']

      auto_wizard_hash['Settings'].each { |setting_data|
        Setting.set( setting_data['name'], setting_data['value'] )
      }
    end

    # add EmailAddresses
    if auto_wizard_hash['EmailAddresses']

      auto_wizard_hash['EmailAddresses'].each { |email_address_data|

        email_address_data_symbolized = email_address_data.symbolize_keys

        email_address_data_symbolized = email_address_data_symbolized.merge(
          {
            updated_by_id: admin_user.id,
            created_by_id: admin_user.id
          }
        )

        EmailAddress.create_if_not_exists(
          email_address_data_symbolized
        )
      }
    end

    admin_user
  end
end
