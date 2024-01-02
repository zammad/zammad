# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Integration::LdapController < ApplicationController
  include Integration::ImportJobBase

  prepend_before_action :authenticate_and_authorize!

  EXCEPTIONS_SPECIAL_TREATMENT = {
    '48, Inappropriate Authentication' => {}, # workaround for issue #1114
    '50, Insufficient Access Rights'   => { error: 'disallow-bind-anon' },
    '53, Unwilling to perform'         => { error: 'disallow-bind-anon' },
  }.freeze

  def discover
    answer_with do

      ldap = ::Ldap.new(params)

      {
        attributes: ldap.preferences
      }
    rescue => e
      EXCEPTIONS_SPECIAL_TREATMENT.find { |msg, _| e.message.ends_with?(msg) }&.last || raise
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
