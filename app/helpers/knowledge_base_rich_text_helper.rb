# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module KnowledgeBaseRichTextHelper
  def prepare_rich_text(input)
    prepare_rich_text_videos(prepare_rich_text_links(input))
  end

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

    Loofah.scrub_fragment(input, scrubber).to_s.html_safe # rubocop:disable Rails/OutputSafety

  end

  def prepare_rich_text_videos(input)
    input.gsub(%r{\((\s*)widget:(\s*)video\W([\s\S])+?\)}) do |match|
      settings = match
        .slice(1...-1)
        .split(',')
        .map { |pair| pair.split(':').map(&:strip) }
        .to_h
        .symbolize_keys

      url = case settings[:provider]
            when 'youtube'
              "https://www.youtube.com/embed/#{settings[:id]}"
            when 'vimeo'
              "https://player.vimeo.com/video/#{settings[:id]}"
            end

      return match if !url

      "<div class='videoWrapper'><iframe allowfullscreen id='#{settings[:provider]}#{settings[:id]}' type='text/html' src='#{url}' frameborder='0'></iframe></div>"
    end
  end
end
