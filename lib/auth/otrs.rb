class Auth::OTRS
  def self.check( user, username, password, config )

    # connect to OTRS
    result = Import::OTRS.auth( username, password )
    return false if !result
    return false if !result['groups_rw']

    # check if required OTRS group exists
    return false if !result['groups_rw'].has_value?( config[:required_group] )

    # sync roles / groups
    if config[:group_role_map]
      config[:group_role_map].each {|otrs_group, role|
        if result['groups_rw'].has_value?( otrs_group )
          role_ids = user.role_ids
          role = Role.where( :name => role ).first
          if role
            role_ids.push role.id
            user.role_ids = role_ids
            user.save
          end
        end
      }
    end

    if config[:always_role]
      config[:always_role].each {|role, active|
        next if !active
        role_ids = user.role_ids
        role = Role.where( :name => role ).first
        if role
          role_ids.push role.id
          user.role_ids = role_ids
          user.save
        end
      }
    end

    return user
  end
end
