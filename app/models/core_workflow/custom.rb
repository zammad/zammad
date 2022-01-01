# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Custom
  include ::Mixin::HasBackends

  def self.list
    backends.map(&:to_s)
  end
end
