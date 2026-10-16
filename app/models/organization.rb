# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Organization < ApplicationModel
  include HasDefaultModelUserRelations

  include HasActivityStreamLog
  include ChecksClientNotification
  include HasHistory
  include HasSearchIndexBackend
  include CanSelector
  include CanCsvImport
  include ChecksHtmlSanitized
  include HasObjectManagerAttributes
  include HasTaskbars
  include HasRecentCloses
  include HasRecentViews
  include CanSelector
  include CanPerformChanges

  include Organization::Assets
  include Organization::Search
  include Organization::SearchIndex
  include Organization::TriggersSubscriptions

  default_scope { order(:id) }

  has_many :members, class_name: 'User', after_add: :member_update, after_remove: :member_update
  has_and_belongs_to_many :secondary_members, class_name: 'User', before_add: %i[check_secondary_member_uniqueness check_secondary_members_on_commit], after_add: :member_update, after_remove: :member_update
  has_many :tickets, class_name: 'Ticket'

  before_create :domain_cleanup
  before_update :domain_cleanup
  after_commit  :members_update_after_create, on: :create

  available_perform_change_actions :attribute_updates

  # workflow checks should run after before_create and before_update callbacks
  # the transaction dispatcher must be run after the workflow checks!
  include ChecksCoreWorkflow
  include HasTransactionDispatcher
  include ChecksSecondaryOrganizationsOnCommit

  core_workflow_screens 'create', 'edit'
  core_workflow_admin_screens 'create', 'edit'
  core_workflow_permission 'ticket.agent', 'admin.organization'

  taskbar_entities 'OrganizationProfile'

  validates :name,   presence: true, uniqueness: { case_sensitive: false }
  validates :domain, presence: { message: 'required when Domain Based Assignment is enabled' }, if: :domain_assignment

  # secondary_members will break eager_load of attributes_with_association_ids because it mixes up with the members relation.
  # so it will get added afterwards
  association_attributes_ignored :secondary_members, :tickets, :created_by, :updated_by
  deep_destroy_associations_include :members, :tickets

  activity_stream_permission 'admin.role'

  validates :note, length: { maximum: 5000 }
  sanitized_html :note, no_images: true

  def all_members
    User
      .left_outer_joins(:organization, :organizations_users)
      .distinct
      .where('organizations.id = :id OR organizations_users.organization_id = :id', id:)
      .reorder(:id)
  end

  def destroy(associations: false)
    if associations
      delete_associations
    else
      unset_associations
    end

    secondary_members_to_touch = secondary_members.records

    super()

    secondary_members_to_touch.each { |user| member_touch(user) }
  end

  def attributes_with_association_ids
    attributes = super
    attributes['secondary_member_ids'] = secondary_member_ids

    # `super` filters before this attribute is merged in, so run the filter over the result again.
    filter_unauthorized_attributes(attributes)
  end

  private

  def domain_cleanup
    return true if domain.blank?

    domain.gsub!(%r{@}, '')
    domain.gsub!(%r{\s*}, '')
    domain.strip!
    domain.downcase!
    true
  end

  def delete_associations
    User.where(organization_id: id).find_each(&:destroy)
    Ticket.where(organization_id: id).find_each(&:destroy)
  end

  def member_update(user)
    # A new organization has its members only once it is saved: the primary ones are saved along
    #   with it and remember the change themselves, the secondary ones are told after the commit.
    return if new_record?

    touch # rubocop:disable Rails/SkipsModelValidations
    member_touch(user)
  end

  # Not iterated in memory: that would load the association and leave an empty target behind on
  #   every organization created without secondary members, masking the ones joined later.
  def members_update_after_create
    secondary_members.find_each { |user| member_touch(user) }
  end

  def member_touch(user)
    user.note_membership_change
    user.touch # rubocop:disable Rails/SkipsModelValidations
  end

  def check_secondary_member_uniqueness(user)
    return if secondary_member_ids.exclude?(user.id)

    errors.add :base, __('Secondary organizations cannot include the same organization twice.')

    raise ActiveRecord::RecordInvalid, self
  end

  def check_secondary_members_on_commit(_user)
    return if new_record?

    check_secondary_organizations_on_commit(User.where(organization_id: id))
  end

  def unset_associations
    User.where(organization_id: id).find_each do |user|
      user.update(organization_id: nil)
    end
    Ticket.where(organization_id: id).find_each do |ticket|
      ticket.update(organization_id: nil)
    end
  end
end
