# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations::Form::UploadCache::Concerns::HandlesAuthorization
  extend ActiveSupport::Concern

  included do

    def authorized?(...)
      form_id = @prepared_arguments[:form_id]

      # A blank form_id names no upload cache to authorize; the mutations do not
      #   clone into one either.
      return super if form_id.blank?

      cache = UploadCache.new(form_id)

      UploadCachePolicy.new(context.current_user, cache).any? && super
    end

  end

end
