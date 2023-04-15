# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TriggerWebhookJob::CustomPayload
  # Following constants are used to determine which classes and methods are
  # allowed to be used in the custom payload. This is to prevent arbitrary
  # code execution.

  ALLOWED_TICKET_CLASSES = %w[
    Ticket
    Ticket::Article
    Ticket::Article::Sender
    Ticket::Article::Type
    Ticket::Priority
    Ticket::State
  ].freeze

  ALLOWED_USER_CLASSES = %w[
    Group
    Organization
    User
  ].freeze

  ALLOWED_NOTIFICATION_CLASSES = %w[
    Struct::Notification
  ].freeze

  ALLOWED_SIMPLE_CLASSES = %w[
    Integer
    String
    Float
  ].freeze

  ALLOWED_RAILS_CLASSES = %w[
    ActiveSupport::TimeWithZone
    ActiveSupport::Duration
  ].freeze

  ALLOWED_CLASSES =
    ALLOWED_TICKET_CLASSES +
    ALLOWED_USER_CLASSES +
    ALLOWED_SIMPLE_CLASSES +
    ALLOWED_RAILS_CLASSES +
    ALLOWED_NOTIFICATION_CLASSES

  ALLOWED_TICKET_METHODS = %w[
    created_by
    current_state_color
    customer
    group
    organization
    owner
    priority
    state
    updated_by
  ].freeze

  ALLOWED_TICKET_ARTICLE_METHODS = %w[
    created_by
    updated_by
    type
    sender
    origin_by
  ].freeze

  ALLOWED_USER_METHODS = %w[
    fullname
  ].freeze

  ALLOWED_NOTIFICATION_METHODS = %w[
    subject
    link
    message
    body
    changes
  ].freeze

  ALLOWED_METHODS = {
    'Ticket'          => ALLOWED_TICKET_METHODS,
    'Ticket::Article' => ALLOWED_TICKET_ARTICLE_METHODS,
    'User'            => ALLOWED_USER_METHODS,
    'Notification'    => ALLOWED_NOTIFICATION_METHODS,
  }.freeze

  DENIED_USER_ATTRIBUTES = %w[
    last_login
    login_failed
    password
    preferences
    group_ids
    authorization_ids
  ].freeze

  DENIED_ATTRIBUTES = {
    'User' => DENIED_USER_ATTRIBUTES,
  }.freeze

  def self.objects_and_subroutines
    data = {
      ticket:                Ticket,
      'ticket.priority':     Ticket::Priority,
      'ticket.state':        Ticket::State,
      'ticket.group':        Group,
      'ticket.owner':        User,
      'ticket.customer':     User,
      'ticket.updated_by':   User,
      'ticket.created_by':   User,
      'ticket.organization': Organization,
      article:               Ticket::Article,
      'article.sender':      Ticket::Article::Sender,
      'article.type':        Ticket::Article::Type,
      'article.created_by':  User,
      'article.updated_by':  User,
      notification:          nil
    }

    data.each do |object, klass|
      if klass.nil?
        data[object] = "TriggerWebhookJob::CustomPayload::ALLOWED_#{object.to_s.upcase}_METHODS".constantize
        next
      end
      data[object] = allowed_subroutines(klass)
    end

    data
  end

  def self.generate(record, tracks, event)
    return {} if record.blank?

    variables = scan(record)
    return JSON.parse(record) if variables.blank?

    tracks.transform_keys!(&:to_sym)
    tracks[:notification] = TriggerWebhookJob::CustomPayload::Notification.generate(tracks, event)
    mappings = parse(variables, tracks)

    # NeverShouldHappen(TM)
    return JSON.parse(record) if mappings.blank?

    replace(record, mappings)

    begin
      valid!(record)
    rescue => e
      return { error: e.message }
    end

    JSON.parse(record)
  end

  # private class methods

  def self.scan(record)
    placeholders = record.scan(%r{(#\{[a-z_.?!]+\})}).flatten.uniq

    return [] if placeholders.blank?

    variables = []
    placeholders.each do |placeholder|
      next if !placeholder.match?(%r{^#\{(.+)\}$})

      placeholder.gsub!(%r{^#\{(.+)\}$}, '\1')
      variables.push(placeholder)
    end

    variables
  end

  def self.parse(variables, tracks)
    mappings = {}

    variables.each do |variable|
      methods = variable.split('.')
      object = methods.shift

      mappings[variable] = validate_object!(object, tracks)
      next if !mappings[variable].nil?

      reference = tracks[object.to_sym]
      mappings[variable] = validate_methods!(methods, reference, object)
    end

    mappings
  end

  def self.validate_methods!(methods, reference, display)
    return "\#{#{display} / missing method}" if methods.blank?

    methods.each_with_index do |method, index|
      display = "#{display}.#{method}"

      result = validate_method!(method, reference, display)
      return result if !result.nil?

      begin
        value = reference.send(method)
      rescue => e
        return "\#{#{display} / #{e.message}}"
      end

      return validate_value!(value, display) if index == methods.size - 1

      reference = value
    end
  end

  def self.validate_value!(value, display)
    return "\#{#{display} / no such method}" if !value.class.to_s.in?(ALLOWED_SIMPLE_CLASSES + ALLOWED_RAILS_CLASSES)

    value
  end

  def self.validate_object!(object, tracks)
    return "\#{no object provided}"         if object.blank?
    return "\#{#{object} / no such object}" if tracks.keys.exclude?(object.to_sym)

    nil
  end

  def self.validate_method!(method, reference, display)
    return "\#{#{display} / missing method}" if method.blank?
    return "\#{#{display} / no such method}" if !allowed_class_method?(method, reference)
    return "\#{#{display} / no such method}" if !reference.respond_to?(method.to_sym)

    nil
  end

  def self.allowed_class_method?(method, reference)
    klass = reference.class
    return false if !klass.to_s.in?(ALLOWED_CLASSES)

    return true if klass.to_s.in?(ALLOWED_SIMPLE_CLASSES + ALLOWED_RAILS_CLASSES)

    klass_subroutines = allowed_subroutines(klass)
    return true if klass_subroutines.include?(method)

    false
  end

  def self.allowed_subroutines(klass)
    return ALLOWED_NOTIFICATION_METHODS if klass.to_s.in?(ALLOWED_NOTIFICATION_CLASSES)

    klass_attributes = klass.attribute_names - (DENIED_ATTRIBUTES[klass.to_s] || [])
    klass_methods    = ALLOWED_METHODS[klass.to_s] || []

    klass_attributes + klass_methods
  end

  def self.replace(record, mappings)
    mappings.each do |variable, value|
      record.gsub!("\#{#{variable}}", value
      .to_s
      .gsub(%r{"}, '\"')
      .gsub(%r{\n}, '\n')
      .gsub(%r{\r}, '\r')
      .gsub(%r{\t}, '\t')
      .gsub(%r{\f}, '\f')
      .gsub(%r{\v}, '\v'))
    end

    record
  end

  def self.valid!(record)
    JSON.parse(record).to_json
  end

  private_class_method %i[
    allowed_class_method?
    allowed_subroutines
    parse
    replace
    scan
    valid!
    validate_method!
    validate_methods!
    validate_object!
    validate_value!
  ]
end
