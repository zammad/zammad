# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Custom
  include ::Mixin::HasBackends

  def self.list
    backends.map(&:to_s)
  end
end
