# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Sets the Snipe-IT assets linked to a ticket and records the change in the ticket history.
#
# Ticket historization ignores the preferences column (see Ticket.history_attributes_ignored),
# so linking and unlinking assets would otherwise leave no trace at all. Every caller which
# writes preferences[:snipeit][:asset_ids] has to go through here.
class Service::Ticket::ExternalReferences::Snipeit::LinkAssets < Service::Base
  requires_current_user!

  attr_reader :ticket, :asset_ids

  def initialize(ticket:, asset_ids:)
    @ticket = ticket
    @asset_ids = Array(asset_ids).map(&:to_i).uniq
  end

  def execute
    ticket.with_lock do
      previous_asset_ids = current_asset_ids

      ticket.preferences[:snipeit] ||= {}
      ticket.preferences[:snipeit][:asset_ids] = asset_ids
      ticket.save!

      # Inside the lock and after the save, so a concurrent update cannot produce history
      # which does not match the stored asset ids.
      log_history(previous_asset_ids)
    end

    ticket
  end

  private

  def current_asset_ids
    Array(ticket.preferences.dig(:snipeit, :asset_ids)).map(&:to_i)
  end

  def log_history(previous_asset_ids)
    (asset_ids - previous_asset_ids).each do |asset_id|
      ticket.history_log('added', current_user.id, { history_attribute: 'snipeit', value_to: Snipeit.asset_label(asset_id) })
    end

    (previous_asset_ids - asset_ids).each do |asset_id|
      ticket.history_log('removed', current_user.id, { history_attribute: 'snipeit', value_to: Snipeit.asset_label(asset_id) })
    end
  end
end
