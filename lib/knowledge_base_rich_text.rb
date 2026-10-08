# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Rendering steps for a knowledge base answer body that need no view context: resolving the
#   editor's answer link markers and expanding the video widget markers (or linking them).
#
# The link target differs per consumer — the public help pages want the `/help/…` path (and the
#   knowledge base's custom address applied to it), the desktop app its own route — so the href is
#   supplied by the caller's block. See KnowledgeBaseRichTextHelper for the view side, which is the
#   only one that may use route/`request` helpers.
module KnowledgeBaseRichText
  module_function

  # @yieldparam translation [KnowledgeBase::Answer::Translation] the link's target
  # @yieldreturn [String] the href to write
  def prepare(input, &)
    expand_video_widgets(resolve_answer_links(input, &))
  end

  def resolve_answer_links(input)
    scrubber = Loofah::Scrubber.new do |node|
      next if node.name != 'a'
      next if !node.key? 'data-target-type'

      case node['data-target-type']
      when 'knowledge-base-answer'
        translation = KnowledgeBase::Answer::Translation.find_by(id: node['data-target-id'])

        node['href'] = translation ? yield(translation) : '#'
      end
    end

    Loofah.scrub_fragment(input, scrubber).to_s
  end

  VIDEO_WIDGET_MARKER = %r{\((\s*)widget:(\s*)video\W([\s\S])+?\)}

  def expand_video_widgets(input)
    input.gsub(VIDEO_WIDGET_MARKER) do |match|
      settings = video_widget_settings(match)

      url = VideoEmbed.embed_url(**settings)
      next '' if url.blank?

      id_attribute = CGI.escapeHTML("#{settings[:provider]}#{settings[:id]}")

      "<div class='videoWrapper'><iframe allowfullscreen id='#{id_attribute}' type='text/html' src='#{CGI.escapeHTML(url.to_s)}' frameborder='0'></iframe></div>"
    end
  end

  # For bodies that leave the knowledge base for a place without an embedded player, e.g. an
  #   article sent by email.
  def link_video_widgets(input)
    input.gsub(VIDEO_WIDGET_MARKER) do |match|
      url = VideoEmbed.watch_url(**video_widget_settings(match))
      next '' if url.blank?

      escaped_url = CGI.escapeHTML(url.to_s)

      "<a href='#{escaped_url}'>#{escaped_url}</a>"
    end
  end

  def video_widget_settings(marker)
    settings = marker
      .slice(1...-1)
      .split(',')
      .filter_map { |pair| pair.split(':', 2).map(&:strip) if pair.include?(':') }
      .to_h
      .symbolize_keys

    { provider: settings[:provider], id: settings[:id], host: settings[:host] }
  end
end
