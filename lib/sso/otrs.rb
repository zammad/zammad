# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module Sso::Otrs
  def self.check( params, config_item )

    endpoint = Setting.get('import_otrs_endpoint')
    return false if !endpoint || endpoint.empty? || endpoint == 'http://otrs_host/otrs'
    return false if !params['SessionID']

    # connect to OTRS
    result = Import::OTRS.session( params['SessionID'] )
    return false if !result

    user = User.where( :login => result['UserLogin'], :active => true ).first
    return user if user

    return false
  end
end