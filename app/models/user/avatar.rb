# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class User
  module Avatar
    extend ActiveSupport::Concern

    included do
      after_create :avatar_for_email_check, unless: -> { BulkImportInfo.enabled? }
      after_update :avatar_for_email_check, unless: -> { BulkImportInfo.enabled? }

      validates :image_source, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true

      before_validation :ensure_existing_image
    end

    def avatar_for_email_check
      return if Setting.get('import_mode')
      return if email.blank?

      email_address_validation = EmailAddressValidation.new(email)
      return if !email_address_validation.valid_format?

      return if !saved_change_to_attribute?('email') && updated_at > Time.zone.now - 10.days

      avatar_auto_detection
    end

    def ensure_existing_image
      return if Setting.get('import_mode')
      return if changes['image'].blank?
      return if ::Avatar.exists?(store_hash: image)

      raise Exceptions::UnprocessableEntity, "Invalid Store reference '#{image}' in 'image' attribute."
    end

    private

    def avatar_auto_detection
      # save/update avatar
      avatar = ::Avatar.auto_detection(
        object:        'User',
        o_id:          id,
        url:           email,
        source:        'app',
        updated_by_id: updated_by_id,
        created_by_id: updated_by_id,
      )

      # update user link
      return if !avatar

      update_column(:image, avatar.store_hash) # rubocop:disable Rails/SkipsModelValidations
      cache_delete
    end
  end
end
