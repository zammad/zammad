# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

    # touch old customer if changed
    customer_id_changed = saved_changes['customer_id']
    if customer_id_changed && customer_id_changed[0] != customer_id_changed[1] && customer_id_changed[0]
      User.find(customer_id_changed[0]).touch # rubocop:disable Rails/SkipsModelValidations
    end

    # touch new/current customer
    customer&.touch # rubocop:disable Rails/SkipsModelValidations

    # touch old organization if changed
    organization_id_changed = saved_changes['organization_id']
    if organization_id_changed && organization_id_changed[0] != organization_id_changed[1] && organization_id_changed[0]
      Organization.find(organization_id_changed[0]).touch # rubocop:disable Rails/SkipsModelValidations
    end

    organization&.touch # rubocop:disable Rails/SkipsModelValidations
  end
end
