# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class DataPrivacyTask < ApplicationModel
  include HasDefaultModelUserRelations

  include DataPrivacyTask::HasActivityStreamLog
  include ChecksClientNotification

  store :preferences

  # optional because related data will get deleted and it would
  # cause validation errors if e.g. the created_by_id of the task
  # would need to get mapped by a deletion
  belongs_to :deletable, polymorphic: true, optional: true

  before_create :prepare_deletion_preview

  validates_with Validations::DataPrivacyTaskValidator

  MAX_PREVIEW_TICKETS = 1000

  def perform
    perform_deletable
    update!(state: 'completed')
  rescue => e
    handle_exception(e)
  end

  def self.cleanup(diff = 12.months)
    where(created_at: ...diff.ago)
      .destroy_all

    true
  end

  private

  # set user inactive before destroy to prevent
  # new online notifications or other events while
  # the deletion process is running
  # https://github.com/zammad/zammad/issues/3942
  def update_inactive(object)
    object.update(active: false)
  end

  def perform_deletable
    return if !deletable_type.constantize.exists?(id: deletable_id)

    prepare_deletion_preview
    save!

    case deletable
    when User
      perform_user_or_organization
    when Ticket
      perform_ticket
    end
  end

  def perform_user_or_organization
    if delete_organization?
      perform_organization(deletable.organization)

      return
    end

    perform_user
  end

  def perform_organization(organization)
    update_inactive(organization)
    organization.members.find_each { |user| update_inactive(user) }
    organization.destroy(associations: true)
  end

  def perform_user
    update_inactive(deletable)
    deletable.destroy
  end

  def perform_ticket
    deletable.destroy
  end

  def handle_exception(e)
    Rails.logger.error e
    preferences[:error] = "ERROR: #{e.inspect}"
    self.state = 'failed'
    save!
  end

  def delete_organization?
    return false if preferences[:delete_organization].blank?
    return false if preferences[:delete_organization] != 'true'
    return false if !deletable.organization
    return false if deletable.organization.members.count != 1

    true
  end

  def prepare_deletion_preview
    prepare_deletion_preview_tickets
    prepare_deletion_preview_user
    prepare_deletion_preview_organization
    prepare_deletion_preview_anonymize
  end

  def prepare_deletion_preview_tickets
    case deletable
    when User
      prepare_deletion_preview_user_tickets
    when Ticket
      prepare_deletion_preview_ticket
    end
  end

  def prepare_deletion_preview_user_tickets
    prepare_deletion_preview_owner_tickets
    prepare_deletion_preview_customer_tickets
  end

  def prepare_deletion_preview_owner_tickets
    preferences[:owner_tickets]       = owner_tickets.limit(MAX_PREVIEW_TICKETS).map(&:number)
    preferences[:owner_tickets_count] = owner_tickets.count
  end

  def prepare_deletion_preview_customer_tickets
    preferences[:customer_tickets]       = customer_tickets.limit(MAX_PREVIEW_TICKETS).map(&:number)
    preferences[:customer_tickets_count] = customer_tickets.count
  end

  def prepare_deletion_preview_ticket
    preferences[:ticket] = {
      title: deletable.title,
    }

    preferences[:customer_tickets]       = [deletable.number]
    preferences[:customer_tickets_count] = 1
  end

  def prepare_deletion_preview_user
    return if !deletable.is_a?(User)

    preferences[:user] = {
      firstname: deletable.firstname,
      lastname:  deletable.lastname,
      email:     deletable.email,
    }
  end

  def prepare_deletion_preview_organization
    return if !deletable.is_a?(User)
    return if !deletable.organization

    preferences[:user][:organization] = deletable.organization.name
  end

  def prepare_deletion_preview_anonymize
    case deletable
    when User
      preferences[:user] = Pseudonymisation.of_hash(preferences[:user])
    when Ticket
      preferences[:ticket] = Pseudonymisation.of_hash(preferences[:ticket])
    end
  end

  def owner_tickets
    @owner_tickets ||= deletable.owner_tickets.reorder(id: 'DESC')
  end

  def customer_tickets
    @customer_tickets ||= deletable.customer_tickets.reorder(id: 'DESC')
  end
end
