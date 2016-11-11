class NotificationFactory::Renderer

=begin

examples how to use

    message_subject = NotificationFactory::Renderer.new(
      {
        ticket: Ticket.first,
      },
      'de-de',
      'some template <b><%= d "ticket.title", false %></b> <%= c "fqdn", false %>',
      false
    ).render

    message_body = NotificationFactory::Renderer.new(
      {
        ticket: Ticket.first,
      },
      'de-de',
      'some template <b><%= d "ticket.title", true %></b> <%= c "fqdn", true %>',
    ).render

=end

  def initialize(objects, locale, template, escape = true)
    @objects = objects
    @locale = locale || 'en-us'
    @template = NotificationFactory::Template.new(template)
    @escape = escape
  end

  def render
    ERB.new(@template.to_s).result(binding)
  end

  # d - data of object
  # d('user.firstname', htmlEscape)
  def d(key, escape = nil)

    # do validaton, ignore some methodes
    if key =~ /(`|\.(|\s*)(save|destroy|delete|remove|drop|update\(|update_att|create\(|new|all|where|find))/i
      return "#{key} (not allowed)"
    end

    value            = nil
    object_methods   = key.split('.')
    object_name      = object_methods.shift.to_sym
    object_refs      = @objects[object_name]
    object_methods_s = ''
    object_methods.each { |method_raw|

      method = method_raw.strip

      if object_methods_s != ''
        object_methods_s += '.'
      end
      object_methods_s += method

      # if method exists
      if !object_refs.respond_to?( method.to_sym )
        value = "\#{#{object_name}.#{object_methods_s} / no such method}"
        break
      end
      object_refs = object_refs.send( method.to_sym )
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

  # a_html - article body in html
  # a_html(article)
  def a_html(article)
    content_type = d "#{article}.content_type", false
    if content_type =~ /html/
      return d "#{article}.body", false
    end
    d("#{article}.body", false).text2html
  end

  # a_text - article body in text
  # a_text(article)
  def a_text(article)
    content_type = d "#{article}.content_type", false
    body = d "#{article}.body", false
    if content_type =~ /html/
      body = body.html2text
    end
    (body.strip + "\n").gsub(/^(.*?)$/, '> \\1')
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
end
