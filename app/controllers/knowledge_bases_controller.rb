# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBasesController < KnowledgeBase::BaseController
  def init
    render json: assets(params[:answer_translation_content_ids])
  end

  def visible_ids
    render json: calculate_visible_ids
  end

  private

  def assets(answer_translation_content_ids = nil)
    if KnowledgeBase.granular_permissions?
      return granular_assets(answer_translation_content_ids) if kb_permissions?
    else
      return editor_assets(answer_translation_content_ids) if kb_permission_editor?
      return reader_assets(answer_translation_content_ids) if kb_permission_reader?
    end

    public_assets
  end

  def calculate_visible_ids
    if KnowledgeBase.granular_permissions? && kb_permissions?
      return KnowledgeBase::InternalAssets.new(current_user).visible_ids
    end

    if kb_permission_editor?
      editor_assets_visible_ids
    elsif kb_permission_reader?
      reader_assets_visible_ids
    else
      {}
    end
  end

  def kb_permissions?
    current_user&.permissions?(%w[knowledge_base.editor knowledge_base.reader])
  end

  def kb_permission_editor?
    current_user&.permissions?('knowledge_base.editor')
  end

  def kb_permission_reader?
    current_user&.permissions?('knowledge_base.reader')
  end

  def granular_assets(answer_translation_content_ids)
    KnowledgeBase::InternalAssets
      .new(current_user, answer_translation_content_ids: answer_translation_content_ids)
      .collect_assets
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

  def editor_assets_visible_ids
    {
      answer_ids:   KnowledgeBase::Answer.pluck(:id),
      category_ids: KnowledgeBase::Category.pluck(:id)
    }
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

  def reader_assets_visible_ids
    {
      answer_ids:   KnowledgeBase::Answer.internal.pluck(:id),
      category_ids: KnowledgeBase::Category.pluck(:id)
    }
  end

  # assets for users who don't have KB permissions
  def public_assets
    return [] if !Setting.get('kb_active_publicly')

    ApplicationModel::CanAssets.reduce(KnowledgeBase.active, {}, :public)
  end
end
