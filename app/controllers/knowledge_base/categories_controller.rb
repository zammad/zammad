# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::CategoriesController < KnowledgeBase::BaseController
  before_action :load_knowledge_base, only: %i[reorder_root_categories reorder_categories reorder_answers]

  def reorder_root_categories
    reorder @knowledge_base.categories.root, params[:ordered_ids], KnowledgeBase::Category
  end

  def reorder_categories
    reorder @category.children, params[:ordered_ids], KnowledgeBase::Category
  end

  def reorder_answers
    reorder @category.answers, params[:ordered_ids], KnowledgeBase::Answer
  end

  private

  def reorder(collection, ids, klass)
    # Check if ids for models in collection are present
    all_ids_present = collection.map(&:id).sort == ids.sort
    raise Exceptions::UnprocessableEntity, 'Provide position of all items in scope' if !all_ids_present

    klass.notify_kb_clients_suspend = true

    klass.acts_as_list_no_update do
      ids.each_with_index do |id, index|
        collection
          .find { |item| item.id == id }
          .update!(position: index)
      end
    end

    klass.notify_kb_clients_suspend = false

    # it's enough to notify about one updated item
    collection.first.touch # rubocop:disable Rails/SkipsModelValidations

    assets = ApplicationModel::CanAssets.reduce(collection, {})
    render json: assets
  end

  def load_knowledge_base
    @knowledge_base = KnowledgeBase.find params[:knowledge_base_id]
    @category = @knowledge_base.categories.find params[:id] if params.key? :id
  end
end
