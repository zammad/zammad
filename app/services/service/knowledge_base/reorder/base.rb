# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared body of the reorder services: how one list inside a node — the knowledge base root or a
#   single category — is sorted, and, while that mode is `manual`, the hand-made order of the records
#   listed in it.
#
# Both the mode and the order belong to the list rather than to the node, so the two scopes of a
#   category are wholly independent: its subcategories and its answers each have a mode column of
#   their own (`category_sorting_mode` / `answer_sorting_mode`, see KnowledgeBase::SORTING_MODES)
#   and an `acts_as_list` of their own (scoped to `parent` and to `category` respectively). Hence
#   one service per scope, each naming the column it writes in #sorting_mode_attribute.
#
# Deliberately not shared with KnowledgeBase::CategoriesController's `reorder_records`, which serves
#   the same two scopes over REST for the legacy interface. That interface has a mode picker of its
#   own, and the two contracts agree wherever they can: the same required whole scope, the same
#   refusal of an order against an automatic mode, and the same two messages for both.
#
# What is left is one difference in each direction, and neither survives being shared. The legacy
#   endpoints write to an inactive knowledge base, which that interface edits deliberately and
#   #active_knowledge_base! here refuses. And they *require* the mode where this stack defaults to
#   the stored one: the mutations are also how the desktop view drags a row without touching the
#   mode, whereas the REST endpoints serve one modal that always has a mode selected.
class Service::KnowledgeBase::Reorder::Base < Service::KnowledgeBase::Base
  # Authorizes through KnowledgeBasePolicy / KnowledgeBase::CategoryPolicy, which need a user.
  requires_current_user!

  attr_reader :sorting_mode, :ordered_ids

  def execute
    # Reordering is editing knowledge base content, so it follows the same rule as every other write
    #   here: only while the knowledge base is active.
    active_knowledge_base!

    ActiveRecord::Base.transaction do
      # The mutations gate a submitted category through CategoryPolicy#update? already, but the
      #   knowledge base root has no such argument to gate. Asking the node itself covers both:
      #   `update?` is editor access on either policy.
      Pundit.authorize current_user, node, :update?

      # A `SELECT ... FOR UPDATE` on the node, held for the rest of the transaction, so two reorders
      #   of the same list can't run their validations and writes interleaved. Without it, two
      #   concurrent requests could both read the same #scope, both pass #ensure_complete_scope!,
      #   and then both run #write_positions! — and since `acts_as_list_no_update` turns off the
      #   sibling shifts that would otherwise keep positions apart, that race can leave the list with
      #   duplicate positions, or with an order neither caller asked for. Locking the node rather
      #   than the individual records serializes the two requests on the one thing they have in
      #   common — every record in #scope belongs to this node — so the second request blocks until
      #   the first commits, then reads and validates against the order the first one actually wrote.
      node.lock!

      ensure_order_for_manual!
      apply_sorting_mode!
      apply_manual_order!

      node
    end
  end

  private

  # @return [KnowledgeBase, KnowledgeBase::Category] the node whose sorting mode is written
  def node
    raise NotImplementedError
  end

  # @return [ActiveRecord::Relation] the records to position — one full scope of an `acts_as_list`,
  #   never a part of one. Memoized by the subclasses, which walk it twice: once to check the
  #   submitted ids against it, once to write the positions.
  def scope
    raise NotImplementedError
  end

  # @return [Symbol] column on #node holding the mode of the list this service orders. A category
  #   stores one per list, so which of the two is written is the subclass's to say.
  def sorting_mode_attribute
    raise NotImplementedError
  end

  # The mode that list is stored with right now.
  def stored_sorting_mode
    node[sorting_mode_attribute]
  end

  # Not written when it is the stored one already, so arming a mode that is armed does not bump the
  #   node's `updated_at` or ping every open browse view with a change that did not happen. Only
  #   ever this list's column: the node's other list keeps the mode it was given.
  def apply_sorting_mode!
    return if sorting_mode.nil?
    return if stored_sorting_mode == sorting_mode

    node.update!(sorting_mode_attribute => sorting_mode)
  end

  # `manual` always arrives with an order (see #ensure_order_for_manual!), so a nil `ordered_ids`
  #   here means an automatic mode was armed and there is nothing to number.
  def apply_manual_order!
    return if ordered_ids.nil?

    ensure_manual_sorting!
    ensure_complete_scope!

    write_positions!
  end

  # `manual` is the only mode that reads a stored order back, and the positions it would read are
  #   whatever the list last held — an arrangement made against a different set of records, or never
  #   made at all. So arming it means saying what the order is: the picker sends the order it is
  #   showing along with the mode, and the list an editor switches to manual keeps looking the way it
  #   looked when they switched.
  #
  # The mirror of #ensure_manual_sorting!, which refuses an order against an automatic mode. Read
  #   before #apply_sorting_mode! writes anything, so a refused call stores neither the mode nor an
  #   order.
  def ensure_order_for_manual!
    return if sorting_mode != 'manual'
    return if !ordered_ids.nil?

    raise Exceptions::UnprocessableContent, __('Provide position of all items in scope')
  end

  # A hand-made order is only ever read back in `manual` mode — the other two derive the order from
  #   the content itself — so storing one against an automatic mode would quietly do nothing. Read
  #   after #apply_sorting_mode! ran, so arming `manual` and sending the order in one call works.
  def ensure_manual_sorting!
    return if stored_sorting_mode == 'manual'

    raise Exceptions::UnprocessableContent, __('Content can only be rearranged while its sorting mode is manual.')
  end

  # The whole scope is required, the same contract the legacy endpoints have: `acts_as_list`
  #   positions are indexes into one list, so a partial set cannot say where the records it leaves
  #   out belong. Note that the desktop view serves answers through a paginated connection — a client
  #   has to have loaded every page before it may send an order.
  def ensure_complete_scope!
    return if scope.map(&:id).sort == ordered_ids.sort

    raise Exceptions::UnprocessableContent, __('Provide position of all items in scope')
  end

  # Positions are written as plain indexes inside `acts_as_list_no_update`, so no callback shifts a
  #   sibling while the whole list is being renumbered (both models declare `top_of_list: 0`).
  #
  # Records already sitting at their index are skipped: dragging one item past another changes a
  #   handful of positions, and updating the untouched ones would bump their `updated_at` and fire a
  #   content-update ping each (TriggersKnowledgeBaseContentUpdates), for an order that did not move.
  def write_positions!
    records = scope.index_by(&:id)

    scope.klass.acts_as_list_no_update do
      ordered_ids.each_with_index do |id, index|
        record = records.fetch(id)

        next if record.position == index

        record.update!(position: index)
      end
    end
  end
end
