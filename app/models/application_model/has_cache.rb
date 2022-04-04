# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module ApplicationModel::HasCache
  extend ActiveSupport::Concern

  def cache_update(_other)
    ActiveSupport::CurrentAttributes.clear_all
    true
  end
end
