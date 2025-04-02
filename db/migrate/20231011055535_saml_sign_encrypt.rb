# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SamlSignEncrypt < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    saml_setting = Setting.find_by(name: 'auth_saml_credentials')
    return if !saml_setting

    required_attributes(saml_setting)
    fingerprint_help(saml_setting)
    add_validations(saml_setting)
    sign_and_encrypt_attributes(saml_setting)
    check_ssl_verify(saml_setting)

    saml_setting.save!(validate: false)
  end

  private

  def required_attributes(saml_setting)
    [1, 2, 3, 5].each do |idx|
      saml_setting.options[:form][idx][:required] = true
    end

    true
  end

  def fingerprint_help(saml_setting)
    saml_setting.options[:form][4][:help] = 'Please note that this attribute is deprecated within one of the next versions of Zammad. Use the IDP certificate instead.'

    true
  end

  def add_validations(saml_setting)
    saml_setting.preferences[:validations] = [
      'Setting::Validation::Saml::RequiredAttributes',
      'Setting::Validation::Saml::TLS',
      'Setting::Validation::Saml::Security',
    ]

    true
  end

  def sign_and_encrypt_attributes(saml_setting)
    saml_setting.options[:form].insert(-2, {
                                         display: 'SSL verification',
                                         null:    true,
                                         name:    'ssl_verify',
                                         tag:     'boolean',
                                         options: {
                                           true  => 'yes',
                                           false => 'no',
                                         },
                                         default: true,
                                         help:    'Turning off SSL verification is a security risk and should be used only temporary. Use this option at your own risk!',
                                       },
                                       {
                                         display: 'Signing & Encrypting',
                                         null:    true,
                                         name:    'security',
                                         tag:     'select',
                                         options: {
                                           'off'     => 'None',
                                           'on'      => 'Signing & Encrypting',
                                           'sign'    => 'Only Signing',
                                           'encrypt' => 'Only Encrypting',
                                         },
                                       },
                                       {
                                         display:     'Certificate (PEM)',
                                         null:        true,
                                         name:        'certificate',
                                         tag:         'textarea',
                                         placeholder: '-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----',
                                       },
                                       {
                                         display:     'Private key (PEM)',
                                         null:        true,
                                         name:        'private_key',
                                         tag:         'textarea',
                                         placeholder: '-----BEGIN RSA PRIVATE KEY-----\n...-----END RSA PRIVATE KEY-----', # gitleaks:allow
                                       },
                                       {
                                         display:     'Private key secret',
                                         null:        true,
                                         name:        'private_key_secret',
                                         tag:         'input',
                                         type:        'password',
                                         single:      true,
                                         placeholder: '',
                                       })

    true
  end

  def check_ssl_verify(_saml_setting)
    if Setting.get('auth_saml_credentials').present? && Setting.get('auth_saml')
      Setting.set('auth_saml_credentials', Setting.get('auth_saml_credentials').merge(ssl_verify: false))
    end

    true
  end
end
