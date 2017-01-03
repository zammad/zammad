# https://developer.zendesk.com/rest_api/docs/core/organizations
module Import
  module Zendesk
    class Organization
      include Import::Zendesk::Helper

      attr_reader :zendesk_id, :id

      def initialize(organization)
        local_organization = ::Organization.create_if_not_exists(local_organization_fields(organization))
        @zendesk_id        = organization.id
        @id                = local_organization.id
      end

      private

      def local_organization_fields(organization)
        {
          name:          organization.name,
          note:          organization.note,
          shared:        organization.shared_tickets,
          # shared: organization.shared_comments, # TODO, not yet implemented
          # }.merge(organization.organization_fields) # TODO
          updated_by_id: 1,
          created_by_id: 1
        }.merge(custom_fields(organization))
      end

      def custom_fields(organization)
        get_fields(organization.organization_fields)
      end
    end
  end
end
