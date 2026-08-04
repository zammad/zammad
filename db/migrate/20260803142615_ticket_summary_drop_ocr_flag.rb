# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class TicketSummaryDropOCRFlag < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup (fresh installs get these tables from CreateBase)
    return if !Setting.exists?(name: 'system_init_done')

    default_ocr = migrate_ticket_summary_config
    apply_default_ocr_provider_connection(default_ocr)
  end

  private

  def apply_default_ocr_provider_connection(default_ocr)
    provider_connection = AI::ProviderConnection.find_by(default_ocr: true)
    return if provider_connection.nil? && !default_ocr
    return if provider_connection.present? && default_ocr

    if provider_connection.nil?
      provider_connection = AI::ProviderConnection.first
      return if provider_connection.nil?
    end

    provider_connection.update!(default_ocr:)
  end

  def migrate_ticket_summary_config
    setting = Setting.find_by(name: 'ai_assistance_ticket_summary_config')
    return true if setting.nil?

    ocr_active = setting.state_current[:value].fetch(:ocr_active, true)

    setting.state_initial = { value: setting.state_initial[:value].except(:ocr_active) }
    setting.state_current = { value: setting.state_current[:value].except(:ocr_active) }
    setting.save!

    ocr_active
  end
end
