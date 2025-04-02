# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Entities::Counts < SystemReport::Plugin
  DESCRIPTION = __('Entity counts of database objects (e.g. ticket count, user count, etc.)').freeze

  def fetch
    counts = {}

    Models.all.each_key do |model|
      counts[model.to_s] = model.count
    end

    counts
  end
end
