# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module NotificationFactory
  TEMPLATE_PATH_STRING = Rails.root.join('app/views/%<type>s/%<template>s/%<filename>s').to_s.freeze
  APPLICATION_TEMPLATE_PATH_STRING = Rails.root.join('app/views/%<type>s/application.%<format>s.erb').to_s.freeze

=begin

  result = NotificationFactory.template_read(
    template: 'password_reset',
    locale: 'en-us',
    format: 'html',
    type: 'mailer',
  )

or

  result = NotificationFactory.template_read(
    template: 'ticket_update',
    locale: 'en-us',
    format: 'md',
    type: 'slack',
  )

returns

  {
    subject: 'some subject',
    body: 'some body',
  }

=end

  class FileNotFoundError < StandardError; end

  def self.template_read(data)
    template_path = template_path(data)

    template = File.readlines(template_path)

    { subject: template.shift, body: template.join }
  end

  def self.template_path(data)
    candidates = template_filenames(data)
      .map { |filename| data.merge(filename: filename) }
      .map { |data_hash| TEMPLATE_PATH_STRING % data_hash }

    found = candidates.find { |candidate| File.exist?(candidate) }

    raise FileNotFoundError, "Missing template files #{candidates}!" if !found

    found
  end
  private_class_method :template_path

  def self.template_filenames(data)
    locale = data[:locale] || Locale.default

    [locale, locale[0, 2], 'en']
      .uniq
      .map { |locale_code| "#{locale_code}.#{data[:format]}.erb" }
      .map { |basename| ["#{basename}.custom", basename] }.flatten
  end
  private_class_method :template_filenames

=begin

  string = NotificationFactory.application_template_read(
    format: 'html',
    type: 'mailer',
  )

or

  string = NotificationFactory.application_template_read(
    format: 'md',
    type: 'slack',
  )

returns

  'some template'

=end

  def self.application_template_read(data)
    File.read(APPLICATION_TEMPLATE_PATH_STRING % data)
  end

end
