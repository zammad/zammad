# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Update assigned customer and organization change_time information on ticket changes.
module Ticket::TouchesAssociations
  extend ActiveSupport::Concern

  included do
    after_create  :ticket_touch_associations
    after_update  :ticket_touch_associations
    after_destroy :ticket_touch_associations
  end

  private

  def ticket_touch_associations

    # return if we run import mode
    return true if Setting.get('import_mode')

    touch_customer
    touch_organization
  end

  def touch_customer
    return if saved_changes['customer_id'].blank?
    return if saved_changes['customer_id'][0] == saved_changes['customer_id'][1]

    # touch old customer
    User.lookup(id: saved_changes['customer_id'][0])&.touch # rubocop:disable Rails/SkipsModelValidations

    # touch new/current customer
    customer&.touch # rubocop:disable Rails/SkipsModelValidations
  end

  def touch_organization
    return if saved_changes['organization_id'].blank?
    return if saved_changes['organization_id'][0] == saved_changes['organization_id'][1]

    # touch old organization
    Organization.lookup(id: saved_changes['organization_id'][0])&.touch # rubocop:disable Rails/SkipsModelValidations

    # touch new organization
    organization&.touch # rubocop:disable Rails/SkipsModelValidations
  end
end
