# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Organization serialization for FormUpdater - fields and convenience methods.
module FormUpdater::Graphql::Serializers::Organization
  # Organization fields that match Gql::Types::OrganizationType
  FIELDS = %w[
    name
    shared
    domain
    domain_assignment
    active
    vip
  ].freeze

  # Serialize an Organization object with standard fields
  #
  # @param organization [Organization] The organization to serialize
  # @return [Hash, nil] Serialized organization hash
  #
  # @example
  #   FormUpdater::Graphql::Serializers::Organization.serialize(org)
  #
  def self.serialize(organization)
    FormUpdater::Graphql::Serializer.serialize(organization, FIELDS)
  end
end
