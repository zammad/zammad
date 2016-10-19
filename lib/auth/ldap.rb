# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

require 'net/ldap'

module Auth::Ldap
  def self.check(username, password, config, user)

    scope = Net::LDAP::SearchScope_WholeSubtree

    # ldap connect
    ldap = Net::LDAP.new( host: config[:host], port: config[:port] )

    # set auth data if needed
    if config[:bind_dn] && config[:bind_pw]
      ldap.auth config[:bind_dn], config[:bind_pw]
    end

    # ldap bind
    begin
      if !ldap.bind
        Rails.logger.info "Can't bind to '#{config[:host]}', #{ldap.get_operation_result.code}, #{ldap.get_operation_result.message}"
        return
      end
    rescue => e
      Rails.logger.info "Can't connect to '#{config[:host]}', #{e}"
      return
    end

    # search user
    filter = "(#{config[:uid]}=#{username})"
    if config[:always_filter] && !config[:always_filter].empty?
      filter = "(&#{filter}#{config[:always_filter]})"
    end
    user_dn = nil
    user_data = {}
    ldap.search( base: config[:base], filter: filter, scope: scope ) do |entry|
      user_data = {}
      user_dn = entry.dn

      # remember attributes for :sync_params
      entry.each do |attribute, values|
        user_data[ attribute.downcase.to_sym ] = ''
        values.each do |value|
          user_data[ attribute.downcase.to_sym ] = value
        end
      end
    end

    if user_dn.nil?
      Rails.logger.info "ldap entry found for user '#{username}' with filter #{filter} failed!"
      return nil
    end

    # try ldap bind with user credentals
    auth = ldap.authenticate user_dn, password
    if !ldap.bind( auth )
      Rails.logger.info "ldap bind with '#{user_dn}' failed!"
      return false
    end

    # create/update user
    if config[:sync_params]
      user_attributes = {
        source: 'ldap',
        updated_by_id: 1,
      }
      config[:sync_params].each { |local_data, ldap_data|
        if user_data[ ldap_data.downcase.to_sym ]
          user_attributes[ local_data.downcase.to_sym] = user_data[ ldap_data.downcase.to_sym ]
        end
      }
      if !user
        user_attributes[:created_by_id] = 1
        user = User.create( user_attributes )
        Rails.logger.debug "user created '#{user.login}'"
      else
        user.update_attributes( user_attributes )
        Rails.logger.debug "user updated '#{user.login}'"
      end
    end

    # return if it was not possible to create user
    return if !user

    # sync roles
    # FIXME

    # sync groups
    # FIXME

    # set always roles
    if config[:always_roles]
      role_ids = user.role_ids
      config[:always_roles].each { |role_name|
        role = Role.where( name: role_name ).first
        next if !role
        if !role_ids.include?( role.id )
          role_ids.push role.id
        end
      }
      user.role_ids = role_ids
      user.save
    end

    # set always groups
    if config[:always_groups]
      group_ids = user.group_ids
      config[:always_groups].each { |group_name|
        group = Group.where( name: group_name ).first
        next if !group
        if !group_ids.include?( group.id )
          group_ids.push group.id
        end
      }
      user.group_ids = group_ids
      user.save
    end

    # take session down
    # - not needed, done by Net::LDAP -

    user
  end
end
