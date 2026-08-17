# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The view side of the answer body rendering: the actual rewriting lives in KnowledgeBaseRichText,
#   this only supplies the public help path as the link target, which needs the route helpers and
#   `request` and is therefore unavailable outside a view/controller.
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
      .gsub(%r{\((\s*)widget:(\s*)video\W([\s\S])+?\)}, '')
      .strip
      .html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  def public_answer_path(translation)
    path = help_answer_path(translation.answer.category.translation_preferred(translation.kb_locale),
                            translation,
                            locale: translation.kb_locale.system_locale.locale)

    custom_path_if_needed path, translation.kb_locale.knowledge_base
  end
end
