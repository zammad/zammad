# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Addons < SystemReport::Plugin
  DESCRIPTION = __('List of installed addons').freeze

  def fetch
    ::Package.all.map do |package|
      package.attributes.delete_if do |k|
        k.in? %w[
          id
          created_at
          updated_at
          created_by_id
          updated_by_id
        ]
      end
    end
  end
end
