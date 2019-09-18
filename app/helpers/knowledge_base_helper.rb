module KnowledgeBaseHelper
  def effective_layout_name(knowledge_base, object)
    layout_prefix = object.present? ? :category : :homepage

    knowledge_base.send("#{layout_prefix}_layout")
  end

  def custom_path_if_needed(path, knowledge_base)
    return path if knowledge_base.custom_address_matches? request

    prefix = knowledge_base.custom_address_uri&.path
    return path if prefix.nil?

    path.gsub(%r{^\/help}, prefix).presence || '/'
  end

  def translation_locale_code(translation)
    translation.kb_locale.system_locale.locale
  end

  def edit_kb_link_label(object)
    suffix = case object
             when KnowledgeBase::Answer
               'answer'
             when KnowledgeBase::Category
               'category'
             when KnowledgeBase
               'knowledge base'
             end

    "edit #{suffix}"
  end

  def build_kb_link(object)
    locale = params.fetch(:locale, object.translation.kb_locale)

    path = case object
           when KnowledgeBase::Answer
             "knowledge_base/#{object.category.knowledge_base.id}/locale/#{locale}/answer/#{object.id}/edit"
           when KnowledgeBase::Category
             "knowledge_base/#{object.knowledge_base.id}/locale/#{locale}/category/#{object.id}/edit"
           when KnowledgeBase
             "knowledge_base/#{object.id}/locale/#{locale}/edit"
           end

    build_zammad_link path
  end

  def build_zammad_link(path)
    host, port = Setting.get('fqdn').split ':'
    scheme     = Setting.get('http_type')

    URI::Generic
      .build(host: host, scheme: scheme, port: port, fragment: path)
      .to_s
  end
end
