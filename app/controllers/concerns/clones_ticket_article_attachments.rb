# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ClonesTicketArticleAttachments
  extend ActiveSupport::Concern

  private

  def article_attachments_clone(article)
    raise Exceptions::UnprocessableEntity, __("Need 'form_id' to add attachments to new form.") if params[:form_id].blank?

    article.clone_attachments('UploadCache', params[:form_id], only_attached_attachments: true)
  end

end
