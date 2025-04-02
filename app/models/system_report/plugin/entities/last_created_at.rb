# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Entities::LastCreatedAt < SystemReport::Plugin
  DESCRIPTION = __('Last created at of database objects (e.g. when was the last trigger created)').freeze

  def fetch
    counts = {}

    Models.all.each_key do |model|
      next if model.column_names.exclude?('created_at')

      counts[model.to_s] = model.maximum(:created_at)
    end

    counts
  end
end
