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
    JSON.parse(File.read(auto_wizard_file_location))
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

    # load text modules
    if auto_wizard_hash['TextModuleLocale']
      if auto_wizard_hash['TextModuleLocale']['Locale']
        begin
          TextModule.load(auto_wizard_hash['TextModuleLocale']['Locale'])
        rescue => e
          Rails.logger.error "Unable to load text modules #{auto_wizard_hash['TextModuleLocale']['Locale']}: #{e.message}"
        end
      end
    end

    # set Settings
    if auto_wizard_hash['Settings']
      auto_wizard_hash['Settings'].each { |setting_data|
        Setting.set(setting_data['name'], setting_data['value'])
      }
    end

    # create EmailAddresses/Channels/Signatures
    model_map = {
      'Organizations' => 'Organization',
    }
    model_map.each { |map_name, model|
      next if !auto_wizard_hash[map_name]
      auto_wizard_hash[map_name].each { |data|
        generic_object = Kernel.const_get(model)
        data.symbolize_keys!
        generic_object.create_or_update_with_ref(data)
      }
    }

    # create Users
    if auto_wizard_hash['Users']
      auto_wizard_hash['Users'].each { |user_data|
        user_data.symbolize_keys!

        if admin_user.id == 1
          if !user_data[:roles] && !user_data[:role_ids]
            user_data[:roles] = Role.where(name: %w(Agent Admin))
          end
          if !user_data[:groups] && !user_data[:group_ids]
            user_data[:groups] = Group.all
          end
        end

        created_user = User.create_or_update_with_ref(user_data)

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
    model_map.each { |map_name, model|
      next if !auto_wizard_hash[map_name]
      auto_wizard_hash[map_name].each { |data|
        generic_object = Kernel.const_get(model)
        data.symbolize_keys!
        generic_object.create_or_update_with_ref(data)
      }
    }

    # reset primary key sequences
    DbHelper.import_post

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
