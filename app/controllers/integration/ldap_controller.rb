# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'ldap'
require_dependency 'ldap/user'
require_dependency 'ldap/group'

class Integration::LdapController < ApplicationController
  include Integration::ImportJobBase

  prepend_before_action { authentication_check && authorize! }

  def discover
    answer_with do

      ldap = ::Ldap.new(params)

      {
        attributes: ldap.preferences
      }
    rescue => e
      # workaround for issue #1114
      raise if !e.message.end_with?(', 48, Inappropriate Authentication')

      # return empty result
      {}

    end
  end

  def bind
    answer_with do
      # create single instance so
      # User and Group don't have to
      # open new connections
      ldap  = ::Ldap.new(params)
      user  = ::Ldap::User.new(params, ldap: ldap)
      group = ::Ldap::Group.new(params, ldap: ldap)

      {
        # the order of these calls is relevant!
        user_filter:     user.filter,
        user_attributes: user.attributes,
        user_uid:        user.uid_attribute,

        # the order of these calls is relevant!
        group_filter:    group.filter,
        groups:          group.list,
        group_uid:       group.uid_attribute,
      }
    end
  end

  private

  def payload_dry_run
    {
      ldap_config: super
    }
  end
end
