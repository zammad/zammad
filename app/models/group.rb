# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Group < ApplicationModel
  include HasDefaultModelUserRelations

  include CanBeImported
  include HasActivityStreamLog
  include ChecksClientNotification
  include HasAuditLogs
  include ChecksHtmlSanitized
  include HasHistory
  include HasObjectManagerAttributes
  include HasCollectionUpdate
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch
  include HasRecursiveCteQuery

  include Group::Assets

  self.audit_log_attributes_ignored = %i[name_last]

  scope :sorted, -> { order(:name) }

  belongs_to :email_address, optional: true
  belongs_to :signature, optional: true
  belongs_to :parent, optional: true, class_name: 'Group'

  # workflow checks should run after before_create and before_update callbacks
  include ChecksCoreWorkflow

  core_workflow_screens 'create', 'edit'
  core_workflow_admin_screens 'create', 'edit'

  before_validation :ensure_name_last_and_parent, :check_parent_not_in_subtree, :check_max_depth, :check_parent_reaches_root

  before_save :update_path
  after_save :update_path_children

  validates :name, uniqueness: { case_sensitive: false }
  validates :name_last, presence: true, format: { without: %r{::}, message: __('No double colons (::) allowed, reserved delimiter') }
  validates :note, length: { maximum: 250 }
  sanitized_html :note, no_images: true

  activity_stream_permission 'admin.group'

  def guess_name_last_and_parent
    split = name.split('::')
    self.name_last = split[-1]

    return if parent_id
    return if split.size == 1

    check_parent = Group.find_by(name: split[..-2].join('::'))

    if check_parent.blank?
      errors.add(:name, 'contains invalid path')
      raise ActiveRecord::RecordInvalid, self
    end

    self.parent = check_parent
  end

  def ensure_name_last_and_parent
    if persisted?
      return if name_last_changed?
      return if !name_changed?
    else
      return if name_last.present?
      return if name.blank?
    end

    guess_name_last_and_parent
  end

  # The tree walks in #check_max_depth read the database, which still holds the old tree while
  # validations run — so moving a group beneath itself or one of its own descendants would look
  # like a legal depth there, yet persist a parent_id cycle. This rejects such a parent explicitly:
  # `all_children` walks the old (database) tree down from self, which is exactly the set of groups
  # that must not become self's parent. New records need no check — they can't be anyone's ancestor
  # yet. Runs after #ensure_name_last_and_parent, which may itself assign `parent` from a path name.
  def check_parent_not_in_subtree
    return if !persisted? || !parent_id_changed? || parent_id.blank?

    raise Exceptions::UnprocessableContent, __('This group cannot be moved into itself.') if parent_id == id
    raise Exceptions::UnprocessableContent, __('This group cannot be moved into one of its children.') if all_children.exists?(id: parent_id)
  end

  def check_max_depth
    new_depth = depth

    raise Exceptions::UnprocessableContent, __('This group exceeds the allowed nesting depth.') if new_depth >= self.class.max_depth

    # `all_children`'s tracked depth is relative to self (1 at self's direct children, since self
    # itself is depth 0), so a descendant's depth-after-save is `new_depth + relative_depth`.
    deepest_relative_depth = all_children.maximum(self.class.recursive_tree_depth_column)
    return if deepest_relative_depth.nil? || new_depth + deepest_relative_depth < self.class.max_depth

    raise Exceptions::UnprocessableContent, __("This group's children would exceed the allowed nesting depth.")
  end

  # #check_max_depth trusts #depth, but on an already-corrupted tree (an existing parent_id cycle,
  # normally impossible thanks to #check_parent_not_in_subtree) the ancestor walk's cycle guard
  # just stops early, making the ancestry look finite and shallow — so attaching a group beneath a
  # cycle member would silently grow the corrupt component. A healthy ancestry always terminates
  # at a root; reject the parent when its chain doesn't. Runs after #check_max_depth so an
  # over-deep (but acyclic) ancestry still gets the more accurate nesting-depth error.
  def check_parent_reaches_root
    return if parent_id.blank?

    topmost = all_parents.last
    return if topmost.nil? || topmost.parent_id.blank?

    raise Exceptions::UnprocessableContent, __('The chosen parent group is part of a circular reference.')
  end

  def update_path
    self.name = path.join('::')
  end

  def update_path_children
    return if !saved_change_to_attribute?(:parent_id) && !saved_change_to_attribute?(:name_last)

    all_children.each do |child|
      child.update_path
      child.save!
    end
  end

  # Returns all ancestors (any depth), ordered from the nearest parent up to the root, using a
  # recursive CTE instead of one query per level. See HasRecursiveCteQuery#with_recursive_tree_cte
  # for cycle-safety and column-naming notes.
  #
  # Seeds from `parent` (always persisted) rather than self, since self may not be persisted yet
  # here (e.g. #path runs from a before_save callback on a new record, where self.id is still nil).
  # That means self's own id never enters the walk's cycle-guard path, so a closed loop reaching
  # back around to self would otherwise re-add it as if it were its own ancestor; #where.not(id:)
  # filters that back out. When self is a new record, id is nil and this is a no-op (id IS NOT NULL
  # matches every real row), which is correct — a not-yet-persisted record can't already appear
  # among its own parent's ancestors.
  def all_parents
    return self.class.none if parent_id.blank?

    self.class
      .with_recursive_tree_cte(direction: :up, seed: parent)
      .where.not(id: id)
  end

  # Returns all descendants (any depth), using a recursive CTE instead of one query per level
  def all_children
    return self.class.none if !persisted?

    self.class
      .with_recursive_tree_cte(direction: :down, seed: self)
      .where.not(id: id)
  end

  # Returns all groups that are too deep to take on children — the ones core workflows remove from
  # parent selection. Instead of computing #depth (itself now a query) for every single Group in
  # the system, this inverts the question: groups that can still take a child are exactly those
  # reachable from a root (parent_id: nil) within `max_depth - 2` levels — a group at depth
  # `max_depth - 1` is itself valid, but its child would sit at depth `max_depth` and be rejected
  # by #check_max_depth. One bounded recursive CTE walking down from all roots finds them, and
  # everything else is the answer. The complement also covers groups no such walk visits at all —
  # members of a parent_id cycle (and their descendants), which have no root above them. Those
  # used to be caught by per-group #depth maxing out its bounded parent walk, and must stay
  # unselectable as parents.
  def self.unselectable_as_parent
    selectable = with_recursive_tree_cte(
      direction: :down,
      seed:      where(parent_id: nil),
      max_depth: max_depth - 2
    )

    where.not(id: selectable.reorder(nil).select(:id))
  end

  def depth
    all_parents.count
  end

  def fullname
    path.join(' › ')
  end

  def path
    all_parents.pluck(:name_last).reverse + [name_last]
  end

  def self.max_depth
    10
  end

  # Cached per request: GroupPolicy#show? calls this for every single group record a customer is
  # authorized against, so e.g. rendering assets of N groups would otherwise run the same query N
  # times. Any model commit clears the cache (ApplicationModel::HasRequestCache), covering changes
  # to both groups and the setting.
  def self.customer_create_groups_with_parent_ids
    Auth::RequestCache.fetch_value('Group/customer_create_groups_with_parent_ids') do
      selected = where(id: Setting.get('customer_ticket_create_group_ids'))

      with_recursive_tree_cte(direction: :up, seed: selected).pluck(:id).uniq
    end
  end
end
