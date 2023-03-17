# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class User
  module Avatar
    extend ActiveSupport::Concern

    included do
      after_commit :fetch_avatar_for_email, on: %i[create update], unless: -> { BulkImportInfo.enabled? }

      before_validation :ensure_existing_image, :remove_invalid_image_source
    end

    def remove_invalid_image_source
      return if image_source.blank?
      return if image_source.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))

      Rails.logger.debug { "Removed invalid image source '#{image_source}' for user '#{email}'" }

      self.image_source = nil
    end

    private

    def fetch_avatar_for_email
      return if Setting.get('import_mode')
      return if !valid_email_for_avatar?

      # save/update avatar using background job
      AvatarCreateJob.perform_later self
    end

    def ensure_existing_image
      return if Setting.get('import_mode')
      return if changes['image'].blank?
      return if ::Avatar.exists?(store_hash: image)

      raise Exceptions::UnprocessableEntity, "Invalid Store reference '#{image}' in 'image' attribute."
    end

    def valid_email_for_avatar?
      return if !saved_change_to_email?
      return if email.blank?

      email_address_validation = EmailAddressValidation.new(email)
      return if !email_address_validation.valid?

      true
    end
  end
end
