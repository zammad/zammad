# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ObjectManagerAttributesAddInternalFlag < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_internal_flag
    migrate_existing_object_manager_attributes
  end

  private

  def add_internal_flag
    add_column :object_manager_attributes, :internal, :boolean, null: false, default: false

    ObjectManager::Attribute.reset_column_information
  end

  def migrate_existing_object_manager_attributes
    # Mark all object manager attributes that are defined in the seeds as internal attributes, so they can't be deleted or deactivated by accident.
    attributes = {
      User:          %w[login firstname lastname email web phone mobile fax organization_id organization_ids password vip note role_ids group_ids active],
      Ticket:        %w[number title customer_id organization_id group_id owner_id state_id pending_time priority_id tags],
      TicketArticle: %w[type_id internal to cc body detected_language],
      Organization:  %w[name shared domain_assignment domain vip note active],
      Group:         %w[name name_last parent_id assignment_timeout follow_up_possible reopen_time_in_days follow_up_assignment email_address_id signature_id shared_drafts note active summary_generation],
    }

    attributes.each do |object, attribute_names|
      # Mark attributes defined in seeds as internal: true
      ObjectManager::Attribute.where(object_lookup_id: ObjectLookup.by_name(object.to_s), name: attribute_names).update_all(internal: true) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
