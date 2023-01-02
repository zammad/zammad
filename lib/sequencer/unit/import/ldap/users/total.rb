# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::Users::Total < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::EmptyDiff

  uses :ldap_config, :ldap_connection, :dry_run

  def process
    state.provide(:statistics_diff) do
      diff.merge(
        total: ((diff[:total] || 0) + total)
      )
    end
  end

  private

  def total
    if !dry_run
      result = Rails.cache.read(cache_key)
    end

    result ||= ldap_connection.count(ldap_config[:user_filter])

    if !dry_run
      Rails.cache.write(cache_key, result, { expires_in: 1.hour })
    end

    result
  end

  def cache_key
    @cache_key ||= "#{ldap_connection.host}::#{ldap_connection.port}::#{ldap_connection.ssl}::#{ldap_connection.base_dn}::#{ldap_config[:user_filter]}"
  end
end
