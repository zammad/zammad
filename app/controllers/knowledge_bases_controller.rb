# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBasesController < KnowledgeBase::BaseController
  def init
    render json: assets(params[:answer_translation_content_ids])
  end

  private

  def assets(answer_translation_content_ids = nil)
    return editor_assets(answer_translation_content_ids) if current_user&.permissions?('knowledge_base.editor')
    return reader_assets(answer_translation_content_ids) if current_user&.permissions?('knowledge_base.reader')

    public_assets
  end

  def editor_assets(answer_translation_content_ids)
    assets = [
      KnowledgeBase,
      KnowledgeBase::Translation,
      KnowledgeBase::Locale,
      KnowledgeBase::Category,
      KnowledgeBase::Category::Translation,
      KnowledgeBase::Answer,
      KnowledgeBase::Answer::Translation
    ].each_with_object({}) do |klass, memo|
      klass.find_in_batches do |group|
        memo = ApplicationModel::CanAssets.reduce(group, memo, :essential)
      end
    end

    if answer_translation_content_ids.present?
      contents = KnowledgeBase::Answer::Translation::Content.where(id: answer_translation_content_ids)
      assets = ApplicationModel::CanAssets.reduce(contents, assets)
    end

    assets
  end

  def reader_assets(answer_translation_content_ids)
    assets = [
      KnowledgeBase,
      KnowledgeBase::Translation,
      KnowledgeBase::Locale,
      KnowledgeBase::Category,
      KnowledgeBase::Category::Translation
    ].each_with_object({}) do |klass, memo|
      klass.find_in_batches do |group|
        memo = ApplicationModel::CanAssets.reduce(group, memo, :essential)
      end
    end

    KnowledgeBase::Answer.internal.find_in_batches do |group|
      assets = ApplicationModel::CanAssets.reduce group, assets, :essential
      translations = KnowledgeBase::Answer::Translation.where(answer_id: group.pluck(:id))
      assets = ApplicationModel::CanAssets.reduce(translations, assets, :essential)

      if answer_translation_content_ids.present?
        contents = KnowledgeBase::Answer::Translation::Content
          .joins(:translation)
          .where(
            id:                                 answer_translation_content_ids,
            knowledge_base_answer_translations: { answer_id: group }
          )

        assets = ApplicationModel::CanAssets.reduce(contents, assets)
      end
    end

    assets
  end

  # assets for users who don't have KB permissions
  def public_assets
    return [] if !Setting.get('kb_active_publicly')

    ApplicationModel::CanAssets.reduce(KnowledgeBase.active, {}, :public)
  end
end
