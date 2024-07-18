# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::StoreValue::Ignore < FormUpdater::StoreValue::Base

  def can_handle_field?(field:, value:)
    ignored_fields.include? field
  end

  def omit_field?(field:, value:)
    true
  end

  private

  def ignored_fields
    %w[
      attachments
      security
      ticket_duplicate_detection
    ]
  end
end
