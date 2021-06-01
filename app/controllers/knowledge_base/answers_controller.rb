# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::AnswersController < KnowledgeBase::BaseController
  include HasPublishing

  # accessible outside of specific Knowledge Base
  # /api/v1/knowledge_bases/recent_answers
  def recent_answers
    answers = KnowledgeBase::Answer.published.limit(10)

    render json: {
      assets:                   ApplicationModel::CanAssets.reduce(answers),
      answer_ids_recent_viewed: answers.pluck(:id)
    }
  end

  # overrides show method to return KnowledgeBase::Answer::Translation::Content when needed
  def show
    object = klass.find(params[:id])
    assets = object.assets({})

    if params[:include_contents].present?
      content_ids = params[:include_contents].split(',')
      contents    = KnowledgeBase::Answer::Translation::Content.where id: content_ids

      assets = ApplicationModel::CanAssets.reduce contents, assets
    end

    render json: { id: object.id, assets: assets }, status: :ok
  end

  # overrides show method to return KnowledgeBase::Answer::Translation::Content that was just saved
  def update
    object = klass.find(params[:id])

    clean_params = klass.association_name_to_id_convert(params)
    clean_params = klass.param_cleanup(clean_params, true)

    object.with_lock do

      # set relations
      object.associations_from_param(params)

      # set attributes
      object.update!(clean_params)

      # execute action if needed
      if (additional_action = params[:additional_action]&.to_sym)
        object.can_be_published_aasm.aasm.fire! additional_action, current_user
      end

    end

    assets = object.assets({})

    contents = object.translations.select { |e| e.content.previous_changes.any? }.map(&:content)
    assets = ApplicationModel::CanAssets.reduce contents, assets

    render json: { id: object.id, assets: assets }, status: :ok
  end

  # overrides show method to return KnowledgeBase::Answer::Translation::Content for the object just created
  def create
    clean_params = klass.association_name_to_id_convert(params)
    clean_params = klass.param_cleanup(clean_params, true)

    # create object
    object = klass.new(clean_params)

    # set relations
    object.associations_from_param(params)

    # save object
    object.save!

    assets = object.assets({})

    contents = object.translations.map(&:content).compact
    assets = ApplicationModel::CanAssets.reduce contents, assets

    render json: { id: object.id, assets: assets }, status: :created
  end

end
