module Import
  module Zendesk
    module GroupFactory
      extend Import::Zendesk::BaseFactory
      extend Import::Zendesk::LocalIDMapperHook
    end
  end
end
