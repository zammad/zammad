module ClonesTicketArticleAttachments
  extend ActiveSupport::Concern

  private

  def article_attachments_clone(article)
    raise Exceptions::UnprocessableEntity, 'Need form_id to attach attachments to new form.' if params[:form_id].blank?

    existing_attachments = Store.list(
      object: 'UploadCache',
      o_id: params[:form_id],
    )
    attachments = []
    article.attachments.each do |new_attachment|
      next if new_attachment.preferences['content-alternative'] == true
      if article.content_type.present? && article.content_type =~ %r{text/html}i
        next if new_attachment.preferences['content_disposition'].present? && new_attachment.preferences['content_disposition'] !~ /inline/
        if new_attachment.preferences['Content-ID'].present? && article.body.present?
          next if article.body.match?(/#{Regexp.quote(new_attachment.preferences['Content-ID'])}/i)
        end
      end
      already_added = false
      existing_attachments.each do |existing_attachment|
        next if existing_attachment.filename != new_attachment.filename || existing_attachment.size != new_attachment.size
        already_added = true
        break
      end
      next if already_added == true
      file = Store.add(
        object: 'UploadCache',
        o_id: params[:form_id],
        data: new_attachment.content,
        filename: new_attachment.filename,
        preferences: new_attachment.preferences,
      )
      attachments.push file
    end

    attachments
  end

end
