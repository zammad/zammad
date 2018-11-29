module Doorkeeper
  class AccessToken < ActiveRecord::Base
    self.table_name = "#{table_name_prefix}oauth_access_tokens#{table_name_suffix}".to_sym

    include AccessTokenMixin

    # Deletes all the Access Tokens created for the specific
    # Application and Resource Owner.
    #
    # @param application_id [Integer] Application ID
    # @param resource_owner [ActiveRecord::Base] Resource Owner model instance
    #
    def self.delete_all_for(application_id, resource_owner)
      where(application_id: application_id,
            resource_owner_id: resource_owner.id).delete_all
    end
    private_class_method :delete_all_for

    # Searches for not revoked Access Tokens associated with the
    # specific Resource Owner.
    #
    # @param resource_owner [ActiveRecord::Base]
    #   Resource Owner model instance
    #
    # @return [ActiveRecord::Relation]
    #   active Access Tokens for Resource Owner
    #
    def self.active_for(resource_owner)
      where(resource_owner_id: resource_owner.id, revoked_at: nil)
    end

    # ORM-specific order method.
    def self.order_method
      :order
    end

    def self.refresh_token_revoked_on_use?
      column_names.include?('previous_refresh_token')
    end

    # ORM-specific DESC order for `:created_at` column.
    def self.created_at_desc
      'created_at desc'
    end
  end
end
