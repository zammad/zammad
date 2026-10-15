# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The view side of the answer body rendering: the actual rewriting lives in KnowledgeBaseRichText,
#   this only supplies the public help path as the link target, which applies the knowledge base's
#   custom address depending on `request` and is therefore unavailable outside a view/controller.
module KnowledgeBaseRichTextHelper
  def prepare_rich_text(input)
    prepare_rich_text_videos(prepare_rich_text_links(input))
  end

  def prepare_rich_text_links(input)
    KnowledgeBaseRichText
      .resolve_answer_links(input) { |translation| public_answer_path(translation) }
      .html_safe # rubocop:disable Rails/OutputSafety
  end

  def prepare_rich_text_videos(input)
    KnowledgeBaseRichText.expand_video_widgets(input)
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
      .gsub(KnowledgeBaseRichText::VIDEO_WIDGET_MARKER, '')
      .strip
      .html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  def public_answer_path(translation)
    custom_path_if_needed translation.public_path, translation.kb_locale.knowledge_base
  end
end
