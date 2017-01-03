module Import
  module Zendesk
    module UserFieldFactory
      extend Import::Zendesk::BaseFactory
      extend Import::Zendesk::LocalIDMapperHook
    end
  end
end
