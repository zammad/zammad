# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations::Form::UploadCache::Concerns::HandlesAuthorization
  extend ActiveSupport::Concern

  included do

    def authorized?(...)
      form_id = @prepared_arguments[:form_id]
      cache = UploadCache.new(form_id)

      UploadCachePolicy.new(context.current_user, cache).any?
    end

  end

end
