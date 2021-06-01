# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ChecksPerformValidation
  extend ActiveSupport::Concern

  included do
    before_create :validate_perform
    before_update :validate_perform
  end

  def validate_perform
    # use Marshal to do a deep copy of the perform hash
    validate_perform = Marshal.load(Marshal.dump(perform))

    check_present = {
      'article.note'         => %w[body subject internal],
      'notification.email'   => %w[body recipient subject],
      'notification.sms'     => %w[body recipient],
      'notification.webhook' => %w[webhook_id],
    }

    check_present.each do |key, values|
      next if validate_perform[key].blank?

      values.each do |value|
        raise Exceptions::UnprocessableEntity, "Invalid perform #{key}, #{value} is missing!" if validate_perform[key][value].blank?
      end
    end

    true
  end
end
