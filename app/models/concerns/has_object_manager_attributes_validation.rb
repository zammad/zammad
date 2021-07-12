# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Copyright (C) 2018 Zammad Foundation, http://zammad-foundation.org/
module HasObjectManagerAttributesValidation
  extend ActiveSupport::Concern

  included do
    # Disable table inheritance to allow columns with the name 'type'.
    self.inheritance_column = nil

    validates_with ObjectManager::Attribute::Validation, on: %i[create update]
  end
end
