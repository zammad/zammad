# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Custom
  include ::Mixin::HasBackends

  def self.list
    backends.map(&:to_s)
  end

  def self.lookup(module_path)
    klass = module_path.to_s.safe_constantize
    return if !klass.is_a?(Class)
    return if !(klass < CoreWorkflow::Custom::Backend)

    klass
  end
end
