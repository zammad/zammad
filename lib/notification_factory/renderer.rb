# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
      escape: false
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

  def initialize(objects:, template:, locale: nil, timezone: nil, escape: true)
    @objects  = objects
    @locale   = locale || Locale.default
    @timezone = timezone || Setting.get('timezone_default')
    @template = NotificationFactory::Template.new(template, escape)
    @escape = escape
  end

  def render
    ERB.new(@template.to_s).result(binding)
  end

  # d - data of object
  # d('user.firstname', htmlEscape)
  def d(key, escape = nil)

    # do validation, ignore some methods
    return "\#{#{key} / not allowed}" if !data_key_valid?(key)

    # aliases
    map = {
      'article.body' => 'article.body_as_text_with_quote.text2html',
      'ticket.tags'  => 'ticket.tag_list',
    }
    if map[key]
      key = map[key]
    end

    # escape in html mode
    if escape
      no_escape = {
        'article.body_as_html'                      => true,
        'article.body_as_text_with_quote.text2html' => true,
      }
      if no_escape[key]
        escape = false
      end
    end

    value          = nil
    object_methods = key.split('.')
    object_name    = object_methods.shift

    # if no object is given, just return
    return '#{no such object}' if object_name.blank? # rubocop:disable Lint/InterpolationCheck

    object_refs = @objects[object_name] || @objects[object_name.to_sym]

    # if object is not in available objects, just return
    return "\#{#{object_name} / no such object}" if !object_refs

    # if content of method is a complex datatype, just return
    if object_methods.blank? && object_refs.class != String && object_refs.class != Float && object_refs.class != Integer
      return "\#{#{key} / no such method}"
    end

    previous_object_refs = ''
    object_methods_s = ''
    object_methods.each do |method_raw|

      method = method_raw.strip

      if method == 'value'
        temp = object_refs
        object_refs = display_value(previous_object_refs, method, object_methods_s, object_refs)
        previous_object_refs = temp
      end

      if object_methods_s != ''
        object_methods_s += '.'
      end
      object_methods_s += method

      next if method == 'value'

      if object_methods_s == ''
        value = "\#{#{object_name}.#{object_methods_s} / no such method}"
        break
      end

      arguments = nil
      if %r{\A(?<method_id>[^(]+)\((?<parameter>[^)]+)\)\z} =~ method

        if parameter != parameter.to_i.to_s
          value = "\#{#{object_name}.#{object_methods_s} / invalid parameter: #{parameter}}"
          break
        end

        begin
          arguments = Array(parameter.to_i)
          method    = method_id
        rescue
          value = "\#{#{object_name}.#{object_methods_s} / #{e.message}}"
          break
        end
      end

      # if method exists
      if !object_refs.respond_to?(method.to_sym)
        value = "\#{#{object_name}.#{object_methods_s} / no such method}"
        break
      end
      begin
        previous_object_refs = object_refs
        object_refs = object_refs.send(method.to_sym, *arguments)

        # body_as_html should trigger the cloning of all inline attachments from the parent article (issue #2399)
        if method.to_sym == :body_as_html && previous_object_refs.respond_to?(:should_clone_inline_attachments)
          previous_object_refs.should_clone_inline_attachments = true
        end
      rescue => e
        value = "\#{#{object_name}.#{object_methods_s} / #{e.message}}"
        break
      end
    end
    placeholder = value || object_refs

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

  private

  def convert_to_timezone(value)
    return Translation.timestamp(@locale, @timezone, value) if value.instance_of?(ActiveSupport::TimeWithZone)
    return Translation.date(@locale, value) if value.instance_of?(Date)

    value
  end

  def escaping(key, escape)
    return escaping(key.join(', '), escape) if key.respond_to?(:join)
    return key if escape == false
    return key if escape.nil? && !@escape

    h key
  end

  def data_key_valid?(key)
    return false if key =~ %r{`|\.(|\s*)(save|destroy|delete|remove|drop|update|create|new|all|where|find|raise|dump|rollback|freeze)}i && key !~ %r{(update|create)d_(at|by)}i

    true
  end

  def display_value(object, method_name, previous_method_names, key)
    return key if method_name != 'value' ||
                  !key.instance_of?(String)

    attributes = ObjectManager::Attribute
                 .where(object_lookup_id: ObjectLookup.by_name(object.class.to_s))
                 .where(name: previous_method_names.split('.').last)

    return key if attributes.count.zero? || attributes.first.data_type != 'select'

    attributes.first.data_option['options'][key] || key
  end
end
