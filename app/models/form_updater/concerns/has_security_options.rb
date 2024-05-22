# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::HasSecurityOptions
  extend ActiveSupport::Concern

  def resolve
    if email_channel? && agent?
      if smime_active? || pgp_active?
        result_initialize_field('security')
      end
      fetch_security_options(SecureMailing::SMIME::SecurityOptions, 'SMIME') if smime_active?
      fetch_security_options(SecureMailing::PGP::SecurityOptions, 'PGP') if pgp_active?
    end

    super
  end

  private

  def fetch_security_options(klass, security_type)
    security_result = klass.new(ticket: data, article: data['article'] || {}).process

    return if !result

    map_result(result['security'], security_type, security_result.signing, 'sign')
    map_result(result['security'], security_type, security_result.encryption, 'encryption')
  end

  def map_result(target, type, result_method, mapped_type)
    push_to_sub_array(target, [:securityAllowed, type], mapped_type, result_method.possible?)
    push_to_sub_array(target, [:securityDefaultOptions, type], mapped_type, result_method.active_by_default?)
    initialize_value(target, type, result_method, mapped_type)
    set_sub_hash(target, [:securityMessages, type, mapped_type], map_message(result_method), result_method.message.present?)
  end

  def initialize_value(target, type, result_method, mapped_type)
    target[:value] ||= {}
    return if target[:value]['method'] && target[:value]['method'] != type

    target[:value]['method'] ||= type
    push_to_sub_array(target, [:value, 'options'], mapped_type, result_method.active_by_default?)
  end

  def map_message(result_method)
    { message: result_method.message, messagePlaceholder: result_method.message_placeholders }
  end

  def push_to_sub_array(hash, keys, value, condition)
    keys[0..-2].each do |key|
      hash[key] ||= {}
      hash = hash[key]
    end
    hash[keys.last] ||= []
    hash[keys.last] << value if condition
  end

  def set_sub_hash(hash, keys, value, condition)
    keys[0..-2].each do |key|
      hash[key] ||= {}
      hash = hash[key]
    end
    hash[keys.last] ||= {}
    hash[keys.last] = value if condition
  end

  def pgp_active?
    Setting.get('pgp_integration')
  end

  def smime_active?
    Setting.get('smime_integration')
  end

  def email_channel?
    data['articleSenderType'] == 'email-out' || data.dig('article', 'articleType') == 'email'
  end

  def agent?
    current_user.permissions?('ticket.agent')
  end
end
