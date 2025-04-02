# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class NotificationFactory::Renderer

=begin

examples how to use

    message_subject = NotificationFactory::Renderer.new(
      objects: {
        ticket: Ticket.first,
      },
      locale: 'de-de',
      timezone: 'America/Port-au-Prince',
      template: 'some template <b>#{ticket.title}</b> {config.fqdn}',
      escape: false,      # Perform HTML encoding on replaced values
      url_encode: false, # Perform URI encoding on replaced values
      trusted: false,     # Allow ERB tags in the template?
    ).render

    message_body = NotificationFactory::Renderer.new(
      objects: {
        ticket: Ticket.first,
      },
      locale: 'de-de',
      timezone: 'America/Port-au-Prince',
      template: 'some template <b>#{ticket.title}</b> #{config.fqdn}',
    ).render

=end

  def initialize(objects:, template:, locale: nil, timezone: nil, escape: true, url_encode: false, trusted: false)
    @objects  = objects
    @locale   = locale || Locale.default
    @timezone = timezone || Setting.get('timezone_default')
    @template = NotificationFactory::Template.new(template, escape || url_encode, trusted)
    @escape = escape
    @url_encode = url_encode
  end

  def render(debug_errors: true)
    @debug_errors = debug_errors
    ERB.new(@template.to_s).result(binding)
  rescue Exception => e # rubocop:disable Lint/RescueException
    raise StandardError, e.message if e.is_a? SyntaxError

    raise
  end

  # d - data of object
  # d('user.firstname', htmlEscape)
  def d(key, escape = nil, escaping: true)

    # do validation, ignore some methods
    return "\#{#{key} / not allowed}" if !data_key_valid?(key)

    article_tags = %w[article last_article last_internal_article last_external_article
                      created_article created_internal_article created_external_article]

    # aliases
    map = { 'ticket.tags' => 'ticket.tag_list', 'ticket.group.name' => 'ticket.group.fullname', 'group.name' => 'group.fullname' }
    article_tags.each do |tag|
      map["#{tag}.body"] = "#{tag}.body_as_text_with_quote.text2html"
    end

    if map[key]
      key = map[key]
    end

    # escape in html mode
    if escape
      no_escape = {}
      article_tags.each do |tag|
        no_escape["#{tag}.body_as_html"] = true
        no_escape["#{tag}.body_as_text_with_quote.text2html"] = true
      end
      if no_escape[key]
        escape = false
      end
    end

    value          = nil
    object_methods = key.split('.')
    object_name    = object_methods.shift

    # if no object is given, just return
    return debug("\#{no such object}") if object_name.blank?

    object_refs = @objects[object_name] || @objects[object_name.to_sym]

    # if object is not in available objects, just return
    return debug("\#{#{object_name} / no such object}") if !object_refs

    # if content of method is a complex datatype, just return
    if object_methods.blank? && object_refs.class != String && object_refs.class != Float && object_refs.class != Integer
      return debug("\#{#{key} / no such method}")
    end

    method_whitelist = %w[avatar]

    previous_object_refs = ''
    object_methods_s = ''
    object_methods.each_with_index do |method_raw, index|

      method = method_raw.strip

      if method == 'value'
        escape = textarea_attributes(previous_object_refs).exclude?(object_methods_s.split('.').last)
        temp = object_refs
        object_refs = display_value(previous_object_refs, method, object_methods_s, object_refs)
        previous_object_refs = temp
      elsif index == object_methods.length - 1 && (is_textarea_attribute = textarea_attributes(object_refs).include?(method))
        temp = object_refs
        object_refs = object_refs.send(method.to_sym)&.text2html
        previous_object_refs = temp
        escape = false
      end

      if object_methods_s != ''
        object_methods_s += '.'
      end
      object_methods_s += method

      next if method == 'value' || is_textarea_attribute

      if object_methods_s == ''
        value = debug("\#{#{object_name}.#{object_methods_s} / no such method}")
        break
      end

      arguments = nil
      if %r{\A(?<method_id>[^(]+)\((?<parameter>[^)]+)\)\z} =~ method

        parameters = []
        parameter.split(',').each do |p|
          p = p.strip!

          if p != p.to_i.to_s
            value = debug("\#{#{object_name}.#{object_methods_s} / invalid parameter: #{p}}")
            break
          end

          parameters << parameter.to_i
        end

        # Ensure that e.g. 'ticket.title.slice(3,4)' is not allowed, but 'ticket.owner.avatar(150,150)' is
        if !parameters.size.eql?(1) && method_whitelist.exclude?(method_id)
          value = debug("\#{#{object_name}.#{object_methods_s} / invalid parameter: #{parameter}}")
          break
        end

        begin
          arguments = parameters
          method    = method_id
        rescue
          value = debug("\#{#{object_name}.#{object_methods_s} / #{e.message}}")
          break
        end
      end

      # if method exists
      if !object_refs.respond_to?(method.to_sym) && method_whitelist.exclude?(method)
        value = debug("\#{#{object_name}.#{object_methods_s} / no such method}")
        break
      end

      begin
        previous_object_refs = object_refs

        if method.to_sym.eql?(:avatar)
          object_refs = handle_user_avatar(previous_object_refs, *arguments)
          escape = false
          break
        end

        object_refs = object_refs.send(method.to_sym, *arguments)

        # body_as_html should trigger the cloning of all inline attachments from the parent article (issue #2399)
        if method.to_sym == :body_as_html && previous_object_refs.respond_to?(:should_clone_inline_attachments)
          previous_object_refs.should_clone_inline_attachments = true
        end
      rescue => e
        value = debug("\#{#{object_name}.#{object_methods_s} / #{e.message}}")
        break
      end
    end
    placeholder = value || object_refs

    return placeholder if !escaping

    escaping(convert_to_timezone(placeholder), escape)
  end

  # c - config
  # c('fqdn', htmlEscape)
  def c(key, escape = nil)
    config = Setting.get(key)
    escaping(config, escape)
  end

  # t - translation
  # t('yes', htmlEscape)
  def t(key, escape = nil)
    translation = Translation.translate(@locale, key)
    escaping(translation, escape)
  end

  # h - htmlEscape
  # h(htmlEscape)
  def h(value)
    return value if !value

    CGI.escapeHTML(convert_to_timezone(value).to_s)
  end

  def dt(params_string)
    datetime_object, format_string, timezone = params_string.scan(%r{(?:['"].*?["']|[^,])+}).map do |param|
      param.strip.sub(%r{^["']}, '').sub(%r{["']$}, '')
    end
    return debug("\#{datetime object missing / invalid parameter}") if datetime_object.blank?

    value = d(datetime_object, escaping: false)

    allowed_classes = %w[ActiveSupport::TimeWithZone Date Time DateTime].freeze
    return debug("\#{#{datetime_object} / invalid parameter}") if allowed_classes.exclude?(value.class.to_s)

    format_string = format_string.presence || '%Y-%m-%d %H:%M:%S'
    timezone      = timezone.presence || @timezone

    begin
      result = value.in_time_zone(timezone).strftime(format_string)
    rescue
      return debug("\#{#{timezone} / invalid parameter}")
    end

    result
  end

  private

  def debug(message)
    @debug_errors ? message : '-'
  end

  def convert_to_timezone(value)
    return Translation.timestamp(@locale, @timezone, value) if value.instance_of?(ActiveSupport::TimeWithZone)
    return Translation.date(@locale, value) if value.instance_of?(Date)

    value
  end

  def escaping(key, escape)
    return escaping(key['value'], escape) if key.is_a?(Hash) && key.key?('value')
    return escaping(key.join(', '), escape) if key.respond_to?(:join)
    return key if escape == false
    return key if escape.nil? && !@escape && !@url_encode

    return ERB::Util.url_encode(key) if @url_encode

    h key
  end

  def data_key_valid?(key)
    return false if key =~ %r{`|\.(|\s*)(save|destroy|delete|remove|drop|update|create|new|all|where|find|raise|dump|rollback|freeze)}i && key !~ %r{(update|create)d_(at|by)}i

    true
  end

  def select_value(attribute, key)
    key     = Array(key)
    options = attribute.data_option['options']
    if options.is_a?(Array)
      key.map { |k| options.detect { |o| o['value'] == k }&.dig('name') || k }
    else
      key.map { |k| options[k] || k }
    end
  end

  def display_value(object, method_name, previous_method_names, key)
    return key if method_name != 'value' ||
                  (!key.instance_of?(String) && !key.instance_of?(Array) && !key.is_a?(Hash))

    attribute = object_manager_attributes(object)
                  .where(name: previous_method_names.split('.').last)
                  .first

    case attribute.data_type
    when %r{^(multi)?select$}
      select_value(attribute, key)
    when 'textarea'
      key.text2html
    when 'autocompletion_ajax_external_data_source'
      key['label']
    else
      key
    end
  end

  def handle_user_avatar(user, width = 60, height = 60)
    return if user.image.blank?

    file = avatar_file(user.image)
    return if file.nil?

    file_content_type = file.preferences['Content-Type'] || file.preferences['Mime-Type']

    "<img src='data:#{file_content_type};base64,#{Base64.strict_encode64(file.content)}' width='#{width}' height='#{height}' />"
  end

  def avatar_file(image_hash)
    Avatar.get_by_hash(image_hash)
  rescue
    nil
  end

  def object_manager_attributes(object)
    ObjectManager::Attribute.where(object_lookup_id: ObjectLookup.by_name(object.class.to_s))
  end

  def textarea_attributes(object)
    object_manager_attributes(object).where(data_type: :textarea).map(&:name)
  end
end
