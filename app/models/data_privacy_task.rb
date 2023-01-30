# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class DataPrivacyTask < ApplicationModel
  include DataPrivacyTask::HasActivityStreamLog
  include ChecksClientNotification

  store :preferences

  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

  # optional because related data will get deleted and it would
  # cause validation errors if e.g. the created_by_id of the task
  # would need to get mapped by a deletion
  belongs_to :deletable, polymorphic: true, optional: true

  before_create :prepare_deletion_preview

  validates_with DataPrivacyTask::Validation

  def perform
    perform_deletable
    update!(state: 'completed')
  rescue => e
    handle_exception(e)
  end

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

    if delete_organization?
      perform_organization
    else
      perform_user
    end
  end

  def perform_organization
    update_inactive(deletable.organization)
    deletable.organization.members.find_each { |user| update_inactive(user) }
    deletable.organization.destroy(associations: true)
  end

  def perform_user
    update_inactive(deletable)
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
    preferences[:owner_tickets]    = deletable.owner_tickets.order(id: 'DESC').map(&:number)
    preferences[:customer_tickets] = deletable.customer_tickets.order(id: 'DESC').map(&:number)
  end

  def prepare_deletion_preview_user
    preferences[:user] = {
      firstname: deletable.firstname,
      lastname:  deletable.lastname,
      email:     deletable.email,
    }
  end

  def prepare_deletion_preview_organization
    return if !deletable.organization

    preferences[:user][:organization] = deletable.organization.name
  end

  def prepare_deletion_preview_anonymize
    preferences[:user] = Pseudonymisation.of_hash(preferences[:user])
  end

  def self.cleanup(diff = 12.months)
    where('created_at < ?', diff.ago).destroy_all
    true
  end
end
