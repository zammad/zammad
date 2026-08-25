# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations::Form::UploadCache::Concerns::HandlesAuthorization
  extend ActiveSupport::Concern

  included do

    def authorized?(...)
      form_id = @prepared_arguments[:form_id]

      # Mutations with an optional form_id have nothing to clone without one -
      #   there is no upload cache to authorize then.
      return super if form_id.blank?

      cache = UploadCache.new(form_id)

      UploadCachePolicy.new(context.current_user, cache).any? && super
    end

  end

end
