# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Ticket::PreProcessArticleContent < Service::BaseWithCurrentUser
  IMAGE_MIME_TYPES = %w[image/jpeg image/jpg image/png image/gif image/tiff image/bmp image/webp].freeze
  MARKER_START     = "[OCR_TEXT_START]\n".freeze
  MARKER_END       = "\n[OCR_TEXT_END]".freeze

  attr_reader :articles, :skip_quotes_strip_first_article

  def initialize(articles:, current_user: nil, skip_quotes_strip_first_article: false)
    super(current_user:) if current_user.present?

    @articles = articles
    @skip_quotes_strip_first_article = skip_quotes_strip_first_article
  end

  def execute
    return prepared_articles if !ocr_active?

    images = collect_all_images(prepared_articles)
    image_texts = recognize_image_texts(images)
    articles_with_recognized_texts(image_texts, prepared_articles)
  end

  private

  def ocr_active?
    Setting.get('ai_provider_config')[:ocr_active]
  end

  def non_plain_article?(article)
    article.content_type && article.content_type !~ %r{text/plain}i
  end

  def prepared_articles
    @prepared_articles ||= articles.map do |article|
      if ocr_active?
        inline_images = select_inline_image_attachments(article)
        image_attachments = select_image_attachments(article, inline_images)
      end

      text = article.body || ''

      # Replace inline images in the HTML body with placeholders.
      text = replace_inline_images_with_placeholders(text, inline_images) if ocr_active? && non_plain_article?(article)

      # Remove quotes and strip HTML to get plain text.
      text = strip_html_and_maybe_remove_quotes(text, article)

      # Remove inline images that were stripped from the body (e.g. in the quotes or signatures).
      inline_images = remove_stripped_inline_images(inline_images, text) if ocr_active? && non_plain_article?(article)

      {
        id:                article.id,
        sender_type:       article.sender.name,
        sender_name:       article.author.fullname,
        created_at:        article.created_at,
        visibility:        article.internal ? 'internal' : 'public',
        text:,
        inline_images:,
        image_attachments:,
      }.compact
    end
  end

  def first_article_id
    @first_article_id ||= articles.first.id
  end

  def select_inline_image_attachments(article)
    article.attachments_inline.select do |attachment|
      IMAGE_MIME_TYPES.include?(attachment_mime_type(attachment))
    end
  end

  def select_image_attachments(article, inline_images)
    article.attachments.reject do |attachment|
      inline_images.any? { |inline_image| inline_image.store_file_id == attachment.store_file_id }
    end.select do |attachment|
      IMAGE_MIME_TYPES.include?(attachment_mime_type(attachment))
    end
  end

  def attachment_mime_type(attachment)
    (attachment.preferences['Content-Type'] || attachment.preferences['Mime-Type'])&.split(';')&.first
  end

  def replace_inline_images_with_placeholders(text, images)
    result = text

    images.each do |attachment|
      cid = extract_content_id(attachment)
      result.gsub!(%r{<img[^>]*?src=('|")?cid:#{Regexp.escape(cid)}('|")?[^>]*?>}i, "[image:#{cid}]")
    end

    result
  end

  def extract_content_id(attachment)
    (attachment.preferences['Content-ID'] || attachment.preferences['Content-Id'])&.gsub(%r{[<>]}, '')
  end

  def strip_html_and_maybe_remove_quotes(text, article)
    text_for_quote_removal = non_plain_article?(article) ? text.html2text(link_style: :markdown) : text
    if article.type == Ticket::Article::Type.lookup(name: 'email') && (!skip_quotes_strip_first_article || article.id != first_article_id)
      Text::QuoteRemover
        .new(text: text_for_quote_removal, remove_signatures: true)
        .remove
    else
      text_for_quote_removal
    end
  end

  def remove_stripped_inline_images(images, text)
    images.reject do |attachment|
      cid = extract_content_id(attachment)
      text.exclude?("[image:#{cid}]")
    end
  end

  def collect_all_images(articles)
    articles
      .flat_map { |article| article[:inline_images] + article[:image_attachments] }
      .uniq(&:store_file_id)
  end

  def recognize_image_texts(images)
    image_texts = {}

    images.each do |image|
      ocr_result = AI::Service::OCR
          .new(current_user:, context_data: { store: image }, prompt_image: image)
          .execute

      image_texts[image.store_file_id] = ocr_result.content
    rescue
      # "Best effort" approach: on errors, simply continue.
      #   Admins can check logs for details.
    end

    image_texts
  end

  def articles_with_recognized_texts(image_texts, articles)
    articles.map do |article|
      text = article[:text]

      # Restore recognized texts for inline image placeholders.
      text = replace_placeholders_with_recognized_texts(text, article[:inline_images], image_texts)

      attachments = attachments_with_recognized_texts(article[:image_attachments], image_texts)

      {
        **article.except(:inline_images, :image_attachments),
        text:,
        attachments:,
      }
    end
  end

  def replace_placeholders_with_recognized_texts(text, images, image_texts)
    result = text

    images.each do |image|
      cid = extract_content_id(image)
      placeholder = "[image:#{cid}]"
      recognized_text = image_texts[image.store_file_id] || ''
      replacement = recognized_text.blank? ? '' : "#{MARKER_START}#{recognized_text}#{MARKER_END}"

      result.gsub!(placeholder, replacement)
    end

    result
  end

  def attachments_with_recognized_texts(images, image_texts)
    images.map do |attachment|
      {
        type: attachment_mime_type(attachment),
        text: image_texts[attachment.store_file_id] || ''
      }
    end
  end

end
