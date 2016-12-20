module Import
  module Zendesk
    module OrganizationFactory
      # we need to loop over each instead of all!
      # so we can use the default import factory here
      extend Import::Factory
      extend Import::Zendesk::LocalIDMapperHook
    end
  end
end
