# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
        .to_h { |pair| pair.split(':', 2).map(&:strip) }
        .symbolize_keys

      url = VideoEmbed.embed_url(provider: settings[:provider], id: settings[:id], host: settings[:host])
      next '' if url.blank?

      id_attribute = CGI.escapeHTML("#{settings[:provider]}#{settings[:id]}")

      "<div class='videoWrapper'><iframe allowfullscreen id='#{id_attribute}' type='text/html' src='#{CGI.escapeHTML(url.to_s)}' frameborder='0'></iframe></div>"
    end
  end

  def simplify_rich_text(input)
    scrubber_link = Loofah::Scrubber.new do |node|
      next if node.name != 'a'
      next if !node.key? 'data-target-type'

      node.replace node.text
    end

    scrubber_images = Loofah::Scrubber.new do |node|
      next if node.name != 'img'

      node.remove
    end

    Loofah
      .html5_fragment(input)
      .scrub!(scrubber_link)
      .scrub!(scrubber_images)
      .to_s
      .gsub(%r{\((\s*)widget:(\s*)video\W([\s\S])+?\)}, '')
      .strip
      .html_safe # rubocop:disable Rails/OutputSafety
  end
end
