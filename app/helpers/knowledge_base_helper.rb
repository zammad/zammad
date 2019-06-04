module KnowledgeBaseHelper
  def render_breadcrumb_if_needed
    objects = []

    if @object
      objects += calculate_breadcrumb_to_category(@category || @object&.parent)
    end

    last = if @alternative.present? && @alternative.translations.any?
             Translation.translate(system_locale_via_uri&.locale, 'Alternative translations')
           else
             @object
           end

    objects << last if last.present?

    return if objects.empty?

    render 'knowledge_base/public/breadcrumb',
           {
             objects:        objects,
             knowledge_base: @knowledge_base
           }
  end

  def calculate_breadcrumb_to_category(category)
    output = [category]

    parent = category
    while (parent = find_category(parent&.parent_id))
      output << parent
    end

    output.compact.reverse
  end

  def visibility_note(object)
    return if !current_user&.permissions?('knowledge_base.editor')

    text = visibility_text(object)

    return if text.nil?

    render 'knowledge_base/public/visibility_note', text: text
  end

  def visibility_text(object)
    case object
    when CanBePublished
      visiblity_text_can_be_published(object)
    when KnowledgeBase::Category
      visiblity_text_category(object)
    end
  end

  def visiblity_text_can_be_published(object)
    case object.can_be_published_aasm.current_state
    when :internal
      'internal'
    when :archived
      'archived'
    when :draft
      'not published'
    end
  end

  def visiblity_text_category(object)
    return if object.public_content?

    if object.self_with_children_answers.only_internal.any?
      'hidden, visible only internally'
    else
      'hidden, no published answers'
    end
  end

  def breadcrumb_path_for(object, locale = params.fetch(:locale))
    case object
    when KnowledgeBase
      help_root_path(locale: locale)
    when KnowledgeBase::Category
      help_category_path(object.translation, locale: locale)
    when KnowledgeBase::Answer
      help_answer_path(object.category.translation, object.translation, locale: locale)
    end
  end

  def effective_layout_name
    layout_prefix = @object.present? ? :category : :homepage

    @knowledge_base.send("#{layout_prefix}_layout")
  end

  def custom_path_if_needed(path, knowledge_base = @knowledge_base)
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

  def kb_top_bar_tag(object)
    case object
    when KnowledgeBase::Answer
      object.can_be_published_aasm.current_state
    when KnowledgeBase::Category
      kb_locale = object&.translation&.kb_locale
      object.public_content?(kb_locale) ? 'Visible' : 'Invisible'
    when KnowledgeBase
      'Published'
    end
  end

  def kb_top_bar_color(object)
    case object
    when KnowledgeBase::Answer
      kb_answer_top_bar_color(object)
    when KnowledgeBase::Category
      kb_locale = object&.translation&.kb_locale
      object.public_content?(kb_locale) ? 'green' : 'yellow'
    when KnowledgeBase
      'green'
    end
  end

  def kb_answer_top_bar_color(answer)
    case answer.can_be_published_aasm.current_state
    when :draft
      'yellow'
    when :internal
      'blue'
    when :published
      'green'
    when :archived
      'red'
    end
  end

  def build_kb_link(object)
    path = case object
           when KnowledgeBase::Answer
             "knowledge_base/#{object.category.knowledge_base.id}/answer/#{object.id}"
           when KnowledgeBase::Category
             "knowledge_base/#{object.knowledge_base.id}/category/#{object.id}"
           when KnowledgeBase
             "knowledge_base/#{object.id}"
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

  def kb_public_page_title
    title = @knowledge_base.translation.title

    if @page_title_error
      suffix = case @page_title_error
               when :not_found
                 'Not Found'
               when :alternatives
                 'Alternative Translations'
               end

      title + " - #{zt(suffix)}"
    elsif @object
      title + " - #{@object.translation.title}"
    else
      title
    end
  end

  def prepare_rich_text_links(input)
    scrubber = Loofah::Scrubber.new do |node|
      next if node.name != 'a'
      next if !node.key? 'data-target-type'

      case node['data-target-type']
      when 'knowledge-base-answer'
        if (translation = KnowledgeBase::Answer::Translation.find_by(id: node['data-target-id']))
          path = help_answer_path(translation.answer.category.translation,
                                  translation.answer.translation,
                                  locale: translation.kb_locale.system_locale.locale)

          node['href'] = custom_path_if_needed path
        else
          node['href'] = '#'
        end
      end
    end

    parsed = Loofah.scrub_fragment(input, scrubber).to_s.html_safe # rubocop:disable Rails/OutputSafety

    parsed
  end
end
