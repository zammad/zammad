class Auth::OTRS
  def self.check( user, username, password, config )

    # connect to OTRS
    result = Import::OTRS.auth( username, password )
    return false if !result
    return false if !result['groups_ro']
    return false if !result['groups_rw']

    # check if required OTRS group exists
    types = {
      :required_group_ro => 'groups_ro',
      :required_group_rw => 'groups_rw',
    }
    types.each {|config_key,result_key|
      if config[config_key]
        return false if !result[result_key].has_value?( config[config_key] )
      end
    }

    # sync roles / groups
    if config[:group_ro_role_map] || config[:group_rw_role_map]
      user.role_ids = []
      user.save
    end
    types = {
      :group_ro_role_map => 'groups_ro',
      :group_rw_role_map => 'groups_rw',
    }
    types.each {|config_key,result_key|
      next if !config[config_key]
      config[config_key].each {|otrs_group, role|
        next if !result[result_key].has_value?( otrs_group )
        role_ids = user.role_ids
        role = Role.where( :name => role ).first
        next if !role
        role_ids.push role.id
        user.role_ids = role_ids
        user.save
      }
    }

    if config[:always_role]
      config[:always_role].each {|role, active|
        next if !active
        role_ids = user.role_ids
        role = Role.where( :name => role ).first
        next if !role
        role_ids.push role.id
        user.role_ids = role_ids
        user.save
      }
    end

    return user
  end
end
