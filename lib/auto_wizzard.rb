module AutoWizzard

  def self.setup

    auto_wizzard_file_name = 'auto_wizzard.json'

    return if !File.file?(auto_wizzard_file_name)

    auto_wizzard_file = File.read(auto_wizzard_file_name)

    auto_wizzard_hash = JSON.parse(auto_wizzard_file)

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
            :updated_by_id => 1,
            :created_by_id => 1
          }
        )

        User.create_or_update(
          user_data_symbolized
        )
      }
    end

    # set Settings
    if auto_wizzard_hash['Settings']

      auto_wizzard_hash['Settings'].each { |setting_data|
        Setting.set( setting_data['name'], setting_data['value'] )
      }
    end

    true
  end
end