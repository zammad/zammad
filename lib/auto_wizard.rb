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

    auto_wizard_file_name     = 'auto_wizard.json'
    auto_wizard_file_location = "#{Rails.root}/#{auto_wizard_file_name}"

    return if !File.file?(auto_wizard_file_location)

    auto_wizard_file = File.read(auto_wizard_file_location)
    auto_wizard_hash = JSON.parse(auto_wizard_file)

    admin_user = User.find( 1 )

    # set Settings
    if auto_wizard_hash['Settings']
      auto_wizard_hash['Settings'].each { |setting_data|
        Setting.set( setting_data['name'], setting_data['value'] )
      }
    end

    # create Organizations
    if auto_wizard_hash['Organizations']
      auto_wizard_hash['Organizations'].each { |organization_data|

        organization_data_symbolized = organization_data.symbolize_keys.merge(
          {
            updated_by_id: admin_user.id,
            created_by_id: admin_user.id
          }
        )

        Organization.create_or_update(
          organization_data_symbolized
        )
      }
    end

    # create Users
    if auto_wizard_hash['Users']

      roles  = Role.where( name: %w(Agent Admin) )
      groups = Group.all

      auto_wizard_hash['Users'].each { |user_data|

        # lookup organization
        if user_data['organization'] && !user_data['organization'].empty?
          organization = Organization.find_by(name: user_data['organization'])
          user_data.delete('organization')
          if organization
            user_data['organization_id'] = organization.id
          end
        end

        user_data_symbolized = user_data.symbolize_keys.merge(
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

    # create EmailAddresses
    if auto_wizard_hash['EmailAddresses']
      auto_wizard_hash['EmailAddresses'].each { |email_address_data|

        email_address_data_symbolized = email_address_data.symbolize_keys.merge(
          {
            updated_by_id: admin_user.id,
            created_by_id: admin_user.id
          }
        )

        EmailAddress.create_or_update(
          email_address_data_symbolized
        )
      }
    end

    # create Channels
    if auto_wizard_hash['Channels']
      auto_wizard_hash['Channels'].each { |channel_data|

        channel_data_symbolized = channel_data.symbolize_keys.merge(
          {
            updated_by_id: admin_user.id,
            created_by_id: admin_user.id
          }
        )

        Channel.create(
          channel_data_symbolized
        )
      }
    end

    # remove auto wizard file
    FileUtils.rm auto_wizard_file_location

    admin_user
  end
end
