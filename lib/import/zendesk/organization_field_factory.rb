module Import
  module Zendesk
    module OrganizationFieldFactory
      extend Import::Zendesk::BaseFactory
      extend Import::Zendesk::LocalIDMapperHook
    end
  end
end
