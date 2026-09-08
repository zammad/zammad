# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Role < ApplicationModel
  include HasDefaultModelUserRelations

  include CanBeImported
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include HasGroups
  include HasCollectionUpdate
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch

  include Role::Assets
  include Role::HasAuditLogs

  self.audit_log_attributes_ignored = %i[preferences]

  has_and_belongs_to_many :users,
                          after_add:    %i[cache_update audit_log_user_add],
                          after_remove: %i[cache_update audit_log_user_remove]
  has_and_belongs_to_many :permissions,
                          before_add:    %i[validate_agent_limit_by_permission validate_permissions],
                          after_add:     %i[cache_update cache_add_kb_permission audit_log_permission_add],
                          before_remove: :last_admin_check_by_permission,
                          after_remove:  %i[cache_update cache_remove_kb_permission audit_log_permission_remove]
  validates               :name, presence: true, uniqueness: { case_sensitive: false }
  store                   :preferences
  has_many                :knowledge_base_permissions, class_name: 'KnowledgeBase::Permission', dependent: :destroy

  before_save    :cleanup_groups_if_not_agent
  before_create  :check_default_at_signup_permissions
  before_update  :last_admin_check_by_attribute, :validate_agent_limit_by_attributes, :check_default_at_signup_permissions

  # workflow checks should run after before_create and before_update callbacks
  include ChecksCoreWorkflow

  core_workflow_screens 'create', 'edit'
  core_workflow_permission 'admin.role'

  # ignore Users because this will lead to huge
  # results for e.g. the Customer role
  association_attributes_ignored :users

  activity_stream_permission 'admin.role'

  validates :note, length: { maximum: 250 }
  sanitized_html :note

=begin

grant permission to role

  role.permission_grant('permission.key')

=end

  def permission_grant(key)
    permission = Permission.lookup(name: key)
    raise "Invalid permission #{key}" if !permission
    return true if permission_ids.include?(permission.id)

    self.permission_ids = permission_ids.push permission.id
    true
  end

=begin

revoke permission of role

  role.permission_revoke('permission.key')

=end

  def permission_revoke(key)
    permission = Permission.lookup(name: key)
    raise "Invalid permission #{key}" if !permission
    return true if permission_ids.exclude?(permission.id)

    self.permission_ids = self.permission_ids -= [permission.id]
    true
  end

=begin

get signup roles

  Role.signup_roles

returns

  [role1, role2, ...]

=end

  def self.signup_roles
    Role.where(active: true, default_at_signup: true)
  end

=begin

get signup role ids

  Role.signup_role_ids

returns

  [role1, role2, ...]

=end

  def self.signup_role_ids
    signup_roles.map(&:id)
  end

=begin

get all roles with permission

  roles = Role.with_permissions('admin.session')

get all roles with permission "admin.session" or "ticket.agent"

  roles = Role.with_permissions(['admin.session', 'ticket.agent'])

returns

  [role1, role2, ...]

=end

  def self.with_permissions(keys)
    permission_ids = Role.permission_ids_by_name(keys)
    Role.joins(:permissions_roles).joins(:permissions).where(
      'permissions_roles.permission_id IN (?) AND roles.active = ? AND permissions.active = ?', permission_ids, true, true
    ).distinct
  end

=begin

check if roles is with permission

  role = Role.find(123)
  role.with_permission?('admin.session')

get if role has permission of "admin.session" or "ticket.agent"

  role.with_permission?(['admin.session', 'ticket.agent'])

returns

  true | false

=end

  def with_permission?(keys)
    permission_ids = Role.permission_ids_by_name(keys)
    return true if Role.joins(:permissions_roles).joins(:permissions).where(
      'roles.id = ? AND permissions_roles.permission_id IN (?) AND permissions.active = ?', id, permission_ids, true
    ).distinct.count.nonzero?

    false
  end

  def self.permission_ids_by_name(keys)
    Array(keys).each_with_object([]) do |key, result|
      ::Permission.with_parents(key).each do |local_key|
        permission = ::Permission.lookup(name: local_key)
        next if !permission

        result.push permission.id
      end
    end
  end

=begin

check if the role grants agent or admin access (i.e. it has the ticket.agent,
admin or any admin.* permission)

  role.grants_elevated_access?

returns

  true | false

=end

  def grants_elevated_access?
    permissions
      .where(active: true)
      .exists?(['permissions.name = :agent OR permissions.name = :admin OR permissions.name LIKE :admin_sub',
                { agent: 'ticket.agent', admin: 'admin', admin_sub: 'admin.%' }])
  end

  private

  def audit_log_user_add(user)
    AuditLog.log_role_assignment(user:, role: self, action_type: 'role_add')
  end

  def audit_log_user_remove(user)
    AuditLog.log_role_assignment(user:, role: self, action_type: 'role_remove')
  end

  def audit_log_permission_add(permission)
    AuditLog.log_association_update(record: self, action_type: 'update', key: 'permissions', added: permission.name)
  end

  def audit_log_permission_remove(permission)
    AuditLog.log_association_update(record: self, action_type: 'update', key: 'permissions', removed: permission.name)
  end

  def validate_permissions(permission)
    Rails.logger.debug { "self permission: #{permission.id}" }

    raise "Permission #{permission.name} is disabled" if permission.preferences[:disabled]

    permission.preferences[:not]
              &.find { |name| name.in?(permissions.map(&:name)) }
              &.tap { |conflict| raise "Permission #{permission} conflicts with #{conflict}" }

    permissions.find { |p| p.preferences[:not]&.include?(permission.name) }
               &.tap { |conflict| raise "Permission #{permission} conflicts with #{conflict}" }
  end

  def last_admin_check_by_attribute
    return true if !will_save_change_to_attribute?('active')
    return true if active != false
    return true if !with_permission?(['admin', 'admin.user'])
    raise Exceptions::UnprocessableContent, __('At least one user needs to have admin permissions.') if !User.admin_user_exists?(except_role_id: [id])

    true
  end

  def last_admin_check_by_permission(permission)
    return true if Setting.get('import_mode')
    return true if permission.name != 'admin' && permission.name != 'admin.user'
    raise Exceptions::UnprocessableContent, __('At least one user needs to have admin permissions.') if !User.admin_user_exists?(except_role_id: [id])

    true
  end

  def validate_agent_limit_by_attributes
    return true if Setting.get('system_agent_limit').blank?
    return true if !will_save_change_to_attribute?('active')
    return true if active != true
    return true if !with_permission?('ticket.agent')

    ticket_agent_role_ids = Role.joins(:permissions).where(permissions: { name: 'ticket.agent', active: true }, roles: { active: true }).pluck(:id)
    currents = User.joins(:roles).where(roles: { id: ticket_agent_role_ids }, users: { active: true }).distinct.pluck(:id)
    news = User.joins(:roles).where(roles: { id: id }, users: { active: true }).distinct.pluck(:id)
    count = currents.concat(news).uniq.count
    raise Exceptions::UnprocessableContent, __('Agent limit exceeded, please check your account settings.') if count > Setting.get('system_agent_limit').to_i

    true
  end

  def validate_agent_limit_by_permission(permission)
    return true if Setting.get('system_agent_limit').blank?
    return true if active != true
    return true if permission.active != true
    return true if permission.name != 'ticket.agent'

    ticket_agent_role_ids = Role.joins(:permissions).where(permissions: { name: 'ticket.agent' }, roles: { active: true }).pluck(:id)
    ticket_agent_role_ids.push(id)
    count = User.joins(:roles).where(roles: { id: ticket_agent_role_ids }, users: { active: true }).distinct.count
    raise Exceptions::UnprocessableContent, __('Agent limit exceeded, please check your account settings.') if count > Setting.get('system_agent_limit').to_i

    true
  end

  def check_default_at_signup_permissions
    return true if !default_at_signup

    forbidden_permissions = permissions.reject(&:allow_signup)
    return true if forbidden_permissions.blank?

    raise Exceptions::UnprocessableContent, "Cannot set default at signup when role has #{forbidden_permissions.join(', ')} permissions."
  end

  def cache_add_kb_permission(permission)
    return if !permission.name.starts_with? 'knowledge_base.'

    touch_knowledge_base_categories
  end

  def cache_remove_kb_permission(permission)
    return if !permission.name.starts_with? 'knowledge_base.'

    downgrade_granular_kb_permissions if KnowledgeBase.granular_permissions?

    touch_knowledge_base_categories
  end

  # A granular selection may not outlive the role permission it was stored against: without any
  #   knowledge base permission left the rows go, and an editor row falls back to reader when only
  #   the reader permission remains. Nothing to do without granular permissions, since there are
  #   no rows.
  def downgrade_granular_kb_permissions
    has_editor = permissions.where(name: 'knowledge_base.editor').any?
    has_reader = permissions.where(name: 'knowledge_base.reader').any?

    KnowledgeBase::Permission
      .where(role: self)
      .each do |elem|
        if !has_editor && !has_reader
          elem.destroy!
        elsif !has_editor && has_reader
          elem.update!(access: 'reader') if elem.access == 'editor'
        end

      end
  end

  # What reaches the accessible-categories cache: KnowledgeBase::AccessibleCategories.cache_key is
  #   fingerprinted on the category cache version, and a role's permission grants appear nowhere in
  #   that key, so the categories have to be bumped for the change to take effect at all.
  #
  # Deliberately not gated on KnowledgeBase.granular_permissions? — the cache is consulted either
  #   way (KnowledgeBase::InternalAssets#accessible_categories resolves through .for_user
  #   unconditionally), and without granular rows the effective access comes straight off the
  #   role's own permission, so revoking it is exactly when the cached struct goes wrong.
  #
  # Written with `touch_all` — one UPDATE, no per-record callbacks — because the sweep edits no
  #   category, it only moves the cache key. Left to `each(&:touch)` every category would enqueue a
  #   ChecksKbClientNotificationJob claiming its content changed (each authorizing that category
  #   against every open session), a ChecksKbClientVisibilityJob and a knowledgeBaseContentUpdates
  #   ping — categories × sessions of work for a change that edited nothing. The same trade-off
  #   KnowledgeBase::Category::Translation.bump_edited_at takes.
  #
  # Suspending those callbacks instead cannot work here, however it is written: this runs inside
  #   the transaction the permissions association write opens, so the after_commit hooks fire when
  #   that commits — after any `ensure` here has lifted the suspension again.
  #   (KnowledgeBase#full_destroy! gets away with it only because its `ensure` sits outside its own
  #   `transaction` block.) The switch is a process-wide class_attribute besides, so holding it
  #   across a request would silence knowledge base notifications for every concurrent one.
  #
  # What the operation does mean — re-check what you can see — is sent once per stack. The legacy
  #   broadcast is also the only signal that reaches the user who just lost access:
  #   ChecksKbClientNotificationJob#notify skips a session no longer holding `knowledge_base.*`.
  #   The subscription ping carries no categories on purpose, which is what
  #   Gql::Subscriptions::KnowledgeBase::ContentUpdates reads as knowledge-base-wide and delivers
  #   to every subscriber — no category changed, but who may browse which of them did.
  #
  # What neither broadcast carries is the new access itself: the legacy client diffs the visible
  #   ids against what it holds, and a downgrade from editor to reader leaves every one of them in
  #   place. It applies the change from the role collection push instead, see
  #   App.KnowledgeBaseAgentController#accessMayHaveChanged.
  #
  # Guarded to run once per transaction, which is what "once per stack" above rests on: the
  #   permissions association fires its callbacks for every single permission added and removed,
  #   while both the sweep and what it announces are about the role's knowledge base access as a
  #   whole. A save swapping the reader permission for the editor one would otherwise sweep the
  #   whole table twice and ping every subscriber twice, each ping making it refetch its browse
  #   queries. The transaction is also the right boundary in the other direction: #permission_grant
  #   and #permission_revoke write the association without saving the role, one transaction each,
  #   and each of those changes does have to reach the clients.
  def touch_knowledge_base_categories
    return if @knowledge_base_categories_swept

    @knowledge_base_categories_swept = true

    KnowledgeBase::Category.touch_all # rubocop:disable Rails/SkipsModelValidations

    transaction = ApplicationModel.current_transaction

    # Both handlers run in other processes, which cannot see the touched categories before this
    #   transaction commits.
    transaction.after_commit do
      @knowledge_base_categories_swept = false

      ChecksKbClientVisibilityJob.perform_later
      Gql::Subscriptions::KnowledgeBase::ContentUpdates.trigger({ categories: [] })
    end

    # A rolled back sweep touched nothing after all, so a later one on the same instance has to
    #   run again — the block that would have cleared the flag is dropped with the rollback.
    transaction.after_rollback do
      @knowledge_base_categories_swept = false
    end
  end

  def cleanup_groups_if_not_agent
    # #with_permissions? SQL-based check does not work on to-be-saved permissions
    # using application-side check instead
    return if permissions.any? { |elem| elem.name == 'ticket.agent' }

    groups.clear
  end
end
