# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::CategoriesController < KnowledgeBase::BaseController
  before_action :load_knowledge_base, only: %i[reorder_root_categories reorder_categories reorder_answers]

  # The three lists a node holds, each with its own mode column and its own `acts_as_list`. The
  #   knowledge base root lists categories only; a category lists its subcategories and its answers
  #   independently of each other (see KnowledgeBase::SORTING_MODES).
  def reorder_root_categories
    reorder_records @knowledge_base.categories.root, @knowledge_base, :category_sorting_mode
  end

  def reorder_categories
    reorder_records @category.children, @category, :category_sorting_mode
  end

  def reorder_answers
    reorder_records @category.answers, @category, :answer_sorting_mode
  end

  private

  # How the legacy interface stores what its "Change order" modal was showing: the mode the list is
  #   listed in, and - while that mode is `manual` - the hand-made order of the records in it.
  #
  # The contract is Service::KnowledgeBase::Reorder::Base's, which serves the same two scopes for the
  #   desktop view, down to the two refusal messages: `sorting_mode` says which mode, and
  #   `ordered_ids` is required with `manual` and refused without it. It differs from that service in
  #   requiring the mode rather than defaulting to the stored one - the picker always has one
  #   selected, and a request that omitted it would be storing an order under whatever mode happened
  #   to be there - and in writing to an inactive knowledge base, which this interface edits
  #   deliberately.
  #
  # @param collection [ActiveRecord::Relation] the whole list being ordered
  # @param node [KnowledgeBase, KnowledgeBase::Category] the node holding that list's mode
  # @param attribute [Symbol] the mode column on it
  def reorder_records(collection, node, attribute)
    mode = params[:sorting_mode]
    ids  = params[:ordered_ids]

    ensure_sorting_mode!(mode)
    ensure_order_for_manual!(mode, ids)
    ensure_manual_sorting!(mode, ids)

    # The mode and the order are one write. Without this a failure part-way through leaves a
    #   mode without its order, or a half-numbered list under a mode that reads it back - the one
    #   state neither interface can render. Outside `acts_as_list_no_update`, as
    #   Service::KnowledgeBase::Reorder::Base#execute has it.
    ActiveRecord::Base.transaction do
      apply_sorting_mode!(node, attribute, mode)

      if ids
        ensure_complete_scope!(collection, ids)
        write_positions!(collection, ids)
      end
    end

    # The node travels back with the records so that App.Collection.loadAssets updates its mode on
    #   the Spine record and the lists re-sort client side.
    render json: ApplicationModel::CanAssets.reduce(collection + [node], {})
  end

  def ensure_sorting_mode!(mode)
    return if mode.present?

    raise Exceptions::UnprocessableContent, __("The required parameter 'sorting_mode' is missing.")
  end

  # `manual` is the only mode that reads a stored order back, and the positions it would read are
  #   whatever the list last held. So picking it means saying what the order is.
  def ensure_order_for_manual!(mode, ids)
    return if mode != 'manual'
    return if !ids.nil?

    raise Exceptions::UnprocessableContent, __('Provide position of all items in scope')
  end

  # The mirror of it: an automatic mode derives the order from the content itself, so storing one
  #   against it would quietly do nothing. Refused before anything is written, so such a call leaves
  #   the stored positions exactly as they were.
  def ensure_manual_sorting!(mode, ids)
    return if mode == 'manual'
    return if ids.nil?

    raise Exceptions::UnprocessableContent, __('Content can only be rearranged while its sorting mode is manual.')
  end

  # Not written when it is the stored one already, as Service::KnowledgeBase::Reorder::Base
  #   #apply_sorting_mode! has it: a plain drag submits the mode it is already in, and rewriting it
  #   would bump the node's `updated_at` and ping every open browse view for a change that did not
  #   happen. An unknown mode still reaches the model's own validation, because it is never the
  #   stored one.
  def apply_sorting_mode!(node, attribute, mode)
    return if node[attribute] == mode

    node.update!(attribute => mode)
  end

  # The whole scope is required: a position is an index into one list, so a partial set cannot say
  #   where the records it leaves out belong.
  def ensure_complete_scope!(collection, ids)
    return if collection.map(&:id).sort == ids.sort

    raise Exceptions::UnprocessableContent, __('Provide position of all items in scope')
  end

  # Positions are written as plain indexes inside `acts_as_list_no_update`, so no callback shifts a
  #   sibling while the whole list is being renumbered.
  #
  # Records already sitting at their index are skipped, as
  #   Service::KnowledgeBase::Reorder::Base#write_positions! does: updating the untouched ones would
  #   bump their `updated_at` and fire a content-update ping each, for an order that did not move.
  #   Worth carrying over now that a save happens on every mode change, not only on a drag.
  def write_positions!(collection, ids)
    records = collection.index_by(&:id)

    collection.klass.acts_as_list_no_update do
      ids.each_with_index do |id, index|
        record = records.fetch(id)

        next if record.position == index

        record.update!(position: index)
      end
    end
  end

  def load_knowledge_base
    @knowledge_base = KnowledgeBase.find params[:knowledge_base_id]
    @category = @knowledge_base.categories.find params[:id] if params.key? :id
  end
end
