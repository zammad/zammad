# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Copyright (C) 2018 Zammad Foundation, http://zammad-foundation.org/
module HasObjectManagerAttributesValidation
  extend ActiveSupport::Concern

  included do
    ActiveSupport::Deprecation.warn("Concern 'HasObjectManagerAttributesValidation' is  deprecated. Use 'HasObjectManagerValidation' instead.")

    include HasObjectManagerAttributes
  end
end
