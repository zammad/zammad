# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Copyright (C) 2018 Zammad Foundation, http://zammad-foundation.org/
module HasObjectManagerAttributesValidation
  extend ActiveSupport::Concern

  included do
    validates_with ObjectManager::Attribute::Validation, on: %i[create update]
  end
end
