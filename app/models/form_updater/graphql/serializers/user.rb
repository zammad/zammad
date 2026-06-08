# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# User serialization for FormUpdater - fields, computed fields, and convenience methods.
module FormUpdater::Graphql::Serializers::User
  # User fields that match Gql::Types::UserType
  FIELDS = %w[
    active
    email
    firstname
    fullname
    image
    lastname
    mobile
    out_of_office
    out_of_office_end_at
    out_of_office_start_at
    phone
    source
    vip
  ].freeze

  # Computed fields for User (not direct attributes, require custom logic)
  COMPUTED_FIELDS = {
    hasSecondaryOrganizations: ->(user) { user.organization_ids.present? }
  }.freeze

  # Serialize a User object with standard fields
  #
  # @param user [User] The user to serialize
  # @param with_organization [Boolean] Include organization relation (default: true)
  # @param with_computed [Boolean] Include computed fields (default: true)
  # @return [Hash, nil] Serialized user hash
  #
  # @example
  #   FormUpdater::Graphql::Serializers::User.serialize(user)
  #   FormUpdater::Graphql::Serializers::User.serialize(user, with_organization: false)
  #
  def self.serialize(user, with_organization: true, with_computed: true)
    relations = with_organization ? { organization: FormUpdater::Graphql::Serializers::Organization::FIELDS } : {}
    computed = with_computed ? COMPUTED_FIELDS : {}

    FormUpdater::Graphql::Serializer.serialize(user, FIELDS, relations: relations, computed_fields: computed)
  end
end
