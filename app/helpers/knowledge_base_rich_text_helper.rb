module KnowledgeBaseRichTextHelper
  def prepare_rich_text_links(input)
    scrubber = Loofah::Scrubber.new do |node|
      next if node.name != 'a'
      next if !node.key? 'data-target-type'

      case node['data-target-type']
      when 'knowledge-base-answer'
        if (translation = KnowledgeBase::Answer::Translation.find_by(id: node['data-target-id']))
          path = help_answer_path(translation.answer.category.translation_preferred(translation.kb_locale),
                                  translation,
                                  locale: translation.kb_locale.system_locale.locale)

          node['href'] = custom_path_if_needed path, translation.kb_locale.knowledge_base
        else
          node['href'] = '#'
        end
      end
    end

    parsed = Loofah.scrub_fragment(input, scrubber).to_s.html_safe # rubocop:disable Rails/OutputSafety

    parsed
  end
end
