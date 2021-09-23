# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Organization < ApplicationModel
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include HasHistory
  include HasSearchIndexBackend
  include CanCsvImport
  include ChecksHtmlSanitized
  include HasObjectManagerAttributes
  include HasTaskbars

  include Organization::Assets
  include Organization::Search
  include Organization::SearchIndex

  include HasTransactionDispatcher

  has_many :members, class_name: 'User'
  has_many :tickets, class_name: 'Ticket'
  belongs_to :created_by,  class_name: 'User'
  belongs_to :updated_by,  class_name: 'User'

  before_create :domain_cleanup
  before_update :domain_cleanup

  # workflow checks should run after before_create and before_update callbacks
  include ChecksCoreWorkflow

  validates :name,   presence: true
  validates :domain, presence: { message: 'required when Domain Based Assignment is enabled' }, if: :domain_assignment

  association_attributes_ignored :tickets, :created_by, :updated_by

  activity_stream_permission 'admin.role'

  sanitized_html :note

  def destroy(associations: false)
    if associations
      delete_associations
    else
      unset_associations
    end
    super()
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
