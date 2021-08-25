# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module CurrentAttributesHelper
  # clear ActiveSupport::CurrentAttributes caches

  def self.included(base)
    base.teardown do
      ActiveSupport::CurrentAttributes.clear_all
    end
  end
end
