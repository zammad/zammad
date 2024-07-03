# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::AttachmentsControllerPolicy < Controllers::ApplicationControllerPolicy
  def show?
    store_object_policy(store_object_owner, allow_kb_preview_token: true)&.show?
  end

  def destroy?
    store_object_policy(store_object_owner)&.destroy?
  end

  def user_required?
    false
  end

  def custom_exception
    ActiveRecord::RecordNotFound.new
  end

  private

  def download_file
    record.send(:download_file)
  end

  def store_object_class
    download_file
      &.store_object
      &.name
      &.safe_constantize
  end

  def store_object_policy(target, allow_kb_preview_token: false)
    if allow_kb_preview_token &&
       attached_to_kb?(target) &&
       (token = record.session[:kb_preview_token])
      token_user = Token.check action: 'KnowledgeBasePreview', token: token
    end

    Pundit.policy token_user || user, target
  end

  def attached_to_kb?(target)
    return true if target.is_a?(KnowledgeBase::Answer::Translation::Content)
    return true if target.is_a?(KnowledgeBase::Answer)

    false
  end

  def store_object_owner
    return Store.find(download_file.id) if store_object_class == UploadCache

    store_object_class
      &.find download_file.o_id
  end
end
