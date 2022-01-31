# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class ApplicationBuildChecksum < BaseQuery

    description 'Checksum of the currently built front-end application. If this changes, the front-end(s) should reload.'

    type String, null: false

    def resolve(...)
      # Use a stable identifier for the development environment, as we use hot reloading there instead.
      return 'development-auto-build' if Rails.env.development?

      filename = Rails.root.join('public/vite/manifest.json')
      Digest::MD5.hexdigest(File.read(filename))
    end

  end
end
