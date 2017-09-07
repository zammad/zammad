# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
require 'ldap'
require 'ldap/user'
require 'ldap/group'

class Integration::LdapController < ApplicationController
  include Integration::ImportJobBase

  prepend_before_action { authentication_check(permission: 'admin.integration.ldap') }

  def discover
    ldap = ::Ldap.new(params)

    render json: {
      result:     'ok',
      attributes: ldap.preferences,
    }
  rescue => e
    # workaround for issue #1114
    if e.message.end_with?(', 48, Inappropriate Authentication')
      result = {
        result:     'ok',
        attributes: {},
      }
    else
      logger.error e
      result = {
        result:  'failed',
        message: e.message,
      }
    end

    render json: result
  end

  def bind
    # create single instance so
    # User and Group don't have to
    # open new connections
    ldap  = ::Ldap.new(params)
    user  = ::Ldap::User.new(params, ldap: ldap)
    group = ::Ldap::Group.new(params, ldap: ldap)

    render json: {
      result: 'ok',

      # the order of these calls is relevant!
      user_filter:     user.filter,
      user_attributes: user.attributes,
      user_uid:        user.uid_attribute,

      # the order of these calls is relevant!
      group_filter: group.filter,
      groups:       group.list,
      group_uid:    group.uid_attribute,
    }
  rescue => e
    logger.error e

    render json: {
      result:  'failed',
      message: e.message,
    }
  end
end
