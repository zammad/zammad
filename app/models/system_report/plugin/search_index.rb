# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::SearchIndex < SystemReport::Plugin
  DESCRIPTION = __('Elasticsearch version').freeze

  def fetch
    SearchIndexBackend.info
  end
end
