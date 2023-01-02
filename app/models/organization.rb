# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Organization < ApplicationModel
  include HasActivityStreamLog
  include ChecksClientNotification
  include HasHistory
  include HasSearchIndexBackend
  include CanCsvImport
  include ChecksHtmlSanitized
  include HasObjectManagerAttributes
  include HasTaskbars

  include Organization::Assets
  include Organization::Search
  include Organization::SearchIndex
  include Organization::TriggersSubscriptions

  include HasTransactionDispatcher

  has_many :members, class_name: 'User'
  has_and_belongs_to_many :secondary_members, class_name: 'User'
  has_many :tickets, class_name: 'Ticket'
  belongs_to :created_by,  class_name: 'User'
  belongs_to :updated_by,  class_name: 'User'

  before_create :domain_cleanup
  before_update :domain_cleanup

  # workflow checks should run after before_create and before_update callbacks
  include ChecksCoreWorkflow

  core_workflow_screens 'create', 'edit'

  validates :name,   presence: true
  validates :domain, presence: { message: 'required when Domain Based Assignment is enabled' }, if: :domain_assignment

  # secondary_members will break eager_load of attributes_with_association_ids because it mixes up with the members relation.
  # so it will get added afterwards
  association_attributes_ignored :secondary_members, :tickets, :created_by, :updated_by

  activity_stream_permission 'admin.role'

  validates :note, length: { maximum: 5000 }
  sanitized_html :note, no_images: true

  def destroy(associations: false)
    if associations
      delete_associations
    else
      unset_associations
    end
    super()
  end

  def attributes_with_association_ids
    attributes = super
    attributes['secondary_member_ids'] = secondary_member_ids
    attributes
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

  def unset_associations
    User.where(organization_id: id).find_each do |user|
      user.update(organization_id: nil)
    end
    Ticket.where(organization_id: id).find_each do |ticket|
      ticket.update(organization_id: nil)
    end
  end
end
