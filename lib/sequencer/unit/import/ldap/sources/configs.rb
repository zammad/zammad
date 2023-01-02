# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::Sources::Configs < Sequencer::Unit::Base
  optional :ldap_config
  provides :configs

  def process
    result = []
    @ldap_config_set = false
    LdapSource.active.find_each do |source|
      next if source.preferences.blank?

      result << source_config(source)
    end

    if ldap_config.present? && !@ldap_config_set
      result << ldap_config
    end

    state.provide(:configs, result)
  end

  def source_config(source)
    if ldap_config.present? && ldap_config[:id] == source.id
      @ldap_config_set = true
      ldap_config
    else
      source.preferences.merge(id: source.id)
    end
  end
end
