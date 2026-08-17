# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Rendering steps for a knowledge base answer body that need no view context: resolving the
#   editor's answer link markers and expanding the video widget markers.
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

  def expand_video_widgets(input)
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
end
