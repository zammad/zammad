module AutoWizzard

=begin

creates or updates Users, EmailAddresses and sets Settings based on the 'auto_wizzard.json' file placed in the root directory.

there is an example file 'contrib/auto_wizzard_example.json'

  AutoWizzard.setup

returns

  the id of the first created User if a 'auto_wizzard.json' file was found and processed, containing at least one entry in Users

  1 if a 'auto_wizzard.json' file was found and processed, containing no Users

  nil if no 'auto_wizzard.json' file was found

=end

  def self.setup

    auto_wizzard_file_name = 'auto_wizzard.json'

    return if !File.file?(auto_wizzard_file_name)

    auto_wizzard_file = File.read(auto_wizzard_file_name)

    auto_wizzard_hash = JSON.parse(auto_wizzard_file)

    admin_user_id = 1

    # create Users
    if auto_wizzard_hash['Users']

      roles  = Role.where( :name => ['Agent', 'Admin'] )
      groups = Group.all

      auto_wizzard_hash['Users'].each { |user_data|

        user_data_symbolized = user_data.symbolize_keys

        user_data_symbolized = user_data_symbolized.merge(
          {
            :active        => true,
            :roles         => roles,
            :groups        => groups,
            :updated_by_id => admin_user_id,
            :created_by_id => admin_user_id
          }
        )

        created_user = User.create_or_update(
          user_data_symbolized
        )

        # use first created user as admin
        next if admin_user_id != 1

        admin_user_id = created_user.id

      }
    end

    # set Settings
    if auto_wizzard_hash['Settings']

      auto_wizzard_hash['Settings'].each { |setting_data|
        Setting.set( setting_data['name'], setting_data['value'] )
      }
    end

    # add EmailAddresses
    if auto_wizzard_hash['EmailAddresses']

      auto_wizzard_hash['EmailAddresses'].each { |email_address_data|

        email_address_data_symbolized = email_address_data.symbolize_keys

        email_address_data_symbolized = email_address_data_symbolized.merge(
          {
            :updated_by_id => admin_user_id,
            :created_by_id => admin_user_id
          }
        )

        EmailAddress.create_if_not_exists(
          email_address_data_symbolized
        )
      }
    end

    admin_user_id
  end
end