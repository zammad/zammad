module ClonesTicketArticleAttachments
  extend ActiveSupport::Concern

  private

  def article_attachments_clone(article)
    raise Exceptions::UnprocessableEntity, 'Need form_id to attach attachments to new form.' if params[:form_id].blank?

    article.clone_attachments('UploadCache', params[:form_id], only_attached_attachments: true)
  end

end
