class NotificationFactory::Template

  def initialize(objects, locale, template, escape = true)
    @objects = objects
    @locale = locale || 'en-us'
    @template = template
    @escape = escape
  end

  def render
    ERB.new(@template).result(binding)
  end

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
    object_methods.each {|method|
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
    return placeholder if escape == false || (escape.nil? && !@escape)
    h placeholder
  end

  def c(key, escape = nil)
    config = Setting.get(key)
    return config if escape == false || (escape.nil? && !@escape)
    h config
  end

  def t(key, escape = nil)
    translation = Translation.translate(@locale, key)
    return translation if escape == false || (escape.nil? && !@escape)
    h translation
  end

  def a(article)
    content_type = d "#{article}.content_type", false
    if content_type =~ /html/
      return d "#{article}.body", false
    end
    d("#{article}.body", false).text2html
  end

  def h(key)
    return key if !key
    CGI.escapeHTML(key.to_s)
  end
end
