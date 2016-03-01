module AutoWizard

=begin

check if auto wizard is enabled

  AutoWizard.enabled?

returns

  true | false

=end

  def self.enabled?
    auto_wizard_file_location = file_location
    return false if !File.file?(auto_wizard_file_location)
    true
  end

=begin

get auto wizard data

  AutoWizard.data

returns

  content of auto wizard file as object

=end

  def self.data
    auto_wizard_file_location = file_location
    raise "So such file #{auto_wizard_file_location}" if !File.file?(auto_wizard_file_location)
    JSON.parse( File.read(auto_wizard_file_location) )
  end

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
    auto_wizard_file_location = file_location

    auto_wizard_hash = data

    admin_user = User.find(1)

    UserInfo.current_user_id = admin_user.id

    # set default calendar
    if auto_wizard_hash['CalendarSetup']
      if auto_wizard_hash['CalendarSetup']['Ip']
        Calendar.init_setup(auto_wizard_hash['CalendarSetup']['Ip'])
      end
    end

    # set Settings
    if auto_wizard_hash['Settings']
      auto_wizard_hash['Settings'].each { |setting_data|
        Setting.set( setting_data['name'], setting_data['value'] )
      }
    end

    # create Organizations
    if auto_wizard_hash['Organizations']
      auto_wizard_hash['Organizations'].each { |organization_data|
        Organization.create_or_update(organization_data.symbolize_keys)
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
          if organization
            user_data['organization_id'] = organization.id
          end
        end
        user_data.delete('organization')

        user_data_symbolized = user_data.symbolize_keys.merge(
          {
            active: true,
            roles: roles,
            groups: groups,
          }
        )
        created_user = User.create_or_update(user_data_symbolized)

        # use first created user as admin
        next if admin_user.id != 1

        admin_user = created_user
        UserInfo.current_user_id = admin_user.id

        # fetch org logo
        if admin_user.email
          Service::Image.organization_suggest(admin_user.email)
        end
      }
    end

    # create EmailAddresses/Channels/Signatures
    model_map = {
      'Channels'       => 'Channel',
      'EmailAddresses' => 'EmailAddress',
      'Signatures'     => 'Signature',
      'Groups'         => 'Group',
    }
    model_map.each {|map_name, model|
      next if !auto_wizard_hash[map_name]
      auto_wizard_hash[map_name].each {|data|
        if data['id'] || data['name']
          Kernel.const_get(model).create_or_update(data.symbolize_keys)
        else
          Kernel.const_get(model).create(data.symbolize_keys)
        end
      }
    }

    # remove auto wizard file
    FileUtils.rm auto_wizard_file_location

    admin_user
  end

  def self.file_location
    auto_wizard_file_name     = 'auto_wizard.json'
    auto_wizard_file_location = "#{Rails.root}/#{auto_wizard_file_name}"
    auto_wizard_file_location
  end
  private_class_method :file_location
end
