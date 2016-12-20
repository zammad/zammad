module Import
  module Zendesk
    module UserFactory
      extend Import::Zendesk::BaseFactory
      extend Import::Zendesk::LocalIDMapperHook
    end
  end
end
