# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::CategoriesController < KnowledgeBase::BaseController
  before_action :load_knowledge_base, only: %i[reorder_root_categories reorder_categories reorder_answers]

  def reorder_root_categories
    reorder_records @knowledge_base.categories.root, params[:ordered_ids], KnowledgeBase::Category
  end

  def reorder_categories
    reorder_records @category.children, params[:ordered_ids], KnowledgeBase::Category
  end

  def reorder_answers
    reorder_records @category.answers, params[:ordered_ids], KnowledgeBase::Answer
  end

  private

  def reorder_records(collection, ids, klass)
    # Check if ids for models in collection are present
    all_ids_present = collection.map(&:id).sort == ids.sort
    raise Exceptions::UnprocessableEntity, __('Provide position of all items in scope') if !all_ids_present

    klass.acts_as_list_no_update do
      ids.each_with_index do |id, index|
        collection
          .find { |item| item.id == id }
          .update!(position: index)
      end
    end

    assets = ApplicationModel::CanAssets.reduce(collection, {})
    render json: assets
  end

  def load_knowledge_base
    @knowledge_base = KnowledgeBase.find params[:knowledge_base_id]
    @category = @knowledge_base.categories.find params[:id] if params.key? :id
  end
end
