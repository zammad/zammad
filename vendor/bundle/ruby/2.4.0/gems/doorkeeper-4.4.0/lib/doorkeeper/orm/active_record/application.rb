module Doorkeeper
  class Application < ActiveRecord::Base
    self.table_name = "#{table_name_prefix}oauth_applications#{table_name_suffix}".to_sym

    include ApplicationMixin
    include ActiveModel::MassAssignmentSecurity if defined?(::ProtectedAttributes)

    has_many :access_grants, dependent: :delete_all, class_name: 'Doorkeeper::AccessGrant'
    has_many :access_tokens, dependent: :delete_all, class_name: 'Doorkeeper::AccessToken'

    validates :name, :secret, :uid, presence: true
    validates :uid, uniqueness: true
    validates :redirect_uri, redirect_uri: true
    validates :confidential, inclusion: { in: [true, false] }

    before_validation :generate_uid, :generate_secret, on: :create

    has_many :authorized_tokens, -> { where(revoked_at: nil) }, class_name: 'AccessToken'
    has_many :authorized_applications, through: :authorized_tokens, source: :application

    # Returns Applications associated with active (not revoked) Access Tokens
    # that are owned by the specific Resource Owner.
    #
    # @param resource_owner [ActiveRecord::Base]
    #   Resource Owner model instance
    #
    # @return [ActiveRecord::Relation]
    #   Applications authorized for the Resource Owner
    #
    def self.authorized_for(resource_owner)
      resource_access_tokens = AccessToken.active_for(resource_owner)
      where(id: resource_access_tokens.select(:application_id).distinct)
    end

    # Fallback to existing, default behaviour of assuming all apps to be
    # confidential if the migration hasn't been run
    def confidential
      return super if self.class.supports_confidentiality?
      ActiveSupport::Deprecation.warn 'You are susceptible to security bug ' \
        'CVE-2018-1000211. Please follow instructions outlined in ' \
        'Doorkeeper::CVE_2018_1000211_WARNING'
      true
    end

    alias_method :confidential?, :confidential

    def self.supports_confidentiality?
      column_names.include?('confidential')
    end

    private

    def generate_uid
      self.uid = UniqueToken.generate if uid.blank?
    end

    def generate_secret
      self.secret = UniqueToken.generate if secret.blank?
    end
  end
end
