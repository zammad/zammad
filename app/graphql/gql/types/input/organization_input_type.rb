# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class OrganizationInputType < Gql::Types::BaseInputObject
    include Gql::Types::Input::Concerns::ProvidesObjectAttributeValues

    description 'The organization insert/update fields.'

    argument :name, String, required: false, description: 'The organization name'
    argument :shared, Boolean, required: false, description: 'The organization shared flag'
    argument :domain, String, required: false, description: 'The organization domain'
    argument :domain_assignment, Boolean, required: false, description: 'The organization domain assignment flag'
    argument :active, Boolean, required: false, description: 'The organization active flag'
    argument :note, String, required: false, description: 'The organization note'
  end
end
