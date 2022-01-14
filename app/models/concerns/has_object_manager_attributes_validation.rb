# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module HasObjectManagerAttributesValidation
  extend ActiveSupport::Concern

  included do
    ActiveSupport::Deprecation.warn("Concern 'HasObjectManagerAttributesValidation' is  deprecated. Use 'HasObjectManagerValidation' instead.")

    include HasObjectManagerAttributes
  end
end
