class NotificationFactory::Renderer

=begin

examples how to use

    message_subject = NotificationFactory::Renderer.new(
      {
        ticket: Ticket.first,
      },
      'de-de',
      'some template <b>#{ticket.title}</b> {config.fqdn}',
      false
    ).render

    message_body = NotificationFactory::Renderer.new(
      {
        ticket: Ticket.first,
      },
      'de-de',
      'some template <b>#{ticket.title}</b> #{config.fqdn}',
    ).render

=end

  def initialize(objects, locale, template, escape = true)
    @objects = objects
    @locale = locale || 'en-us'
    @template = NotificationFactory::Template.new(template, escape)
    @escape = escape
  end

  def render
    ERB.new(@template.to_s).result(binding)
  end

  # d - data of object
  # d('user.firstname', htmlEscape)
  def d(key, escape = nil)

    # do validaton, ignore some methodes
    return "\#{#{key} / not allowed}" if !data_key_valid?(key)

    # aliases
    map = {
      'article.body' => 'article.body_as_text_with_quote.text2html',
    }
    if map[key]
      key = map[key]
    end

    # escape in html mode
    if escape
      no_escape = {
        'article.body_as_html' => true,
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
    return "\#{no such object}" if object_name.empty?
    object_refs = @objects[object_name] || @objects[object_name.to_sym]

    # if object is not in avalable objects, just return
    return "\#{#{object_name} / no such object}" if !object_refs

    # if content of method is a complex datatype, just return
    if object_methods.empty? && object_refs.class != String && object_refs.class != Float && object_refs.class != Integer
      return "\#{#{key} / no such method}"
    end
    object_methods_s = ''
    object_methods.each { |method_raw|

      method = method_raw.strip

      if object_methods_s != ''
        object_methods_s += '.'
      end
      object_methods_s += method

      if object_methods_s == ''
        value = "\#{#{object_name}.#{object_methods_s} / no such method}"
        break
      end

      # if method exists
      if !object_refs.respond_to?(method.to_sym)
        value = "\#{#{object_name}.#{object_methods_s} / no such method}"
        break
      end
      begin
        object_refs = object_refs.send(method.to_sym)
      rescue => e
        object_refs = "\#{#{object_name}.#{object_methods_s} / e.message}"
      end
    }
    placeholder = if !value
                    object_refs
                  else
                    value
                  end
    escaping(placeholder, escape)
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
  # h('fqdn', htmlEscape)
  def h(key)
    return key if !key
    CGI.escapeHTML(key.to_s)
  end

  private

  def escaping(key, escape)
    return key if escape == false
    return key if escape.nil? && !@escape
    h key
  end

  def data_key_valid?(key)
    return false if key =~ /`|\.(|\s*)(save|destroy|delete|remove|drop|update|create|new|all|where|find|raise|dump|rollback|freeze)/i && key !~ /(update|create)d_(at|by)/i
    true
  end

end
