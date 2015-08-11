# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'import/otrs'

module Auth::Otrs
  def self.check(username, password, config, user)

    endpoint = Setting.get('import_otrs_endpoint')
    return false if !endpoint
    return false if endpoint.empty?
    return false if endpoint == 'http://otrs_host/otrs'

    # connect to OTRS
    result = Import::OTRS.auth(username, password)
    return false if !result
    return false if !result['groups_ro']
    return false if !result['groups_rw']
    return false if !result['user']

    user = User.where(login: result['user']['UserLogin'], active: true).first
    return false if !user

    # sync / check permissions
    Import::OTRS.permission_sync(user, result, config)

    user
  end
end
