# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Template::Interpolation::Engine::Track
  include Mixin::RequiredSubPaths

  def self.root?
    false
  end

  def self.klass
    raise 'not implemented'
  end

  def self.functions
    klass.constantize.attribute_names
  end

  def self.replacements
    return {} if !root?

    raise 'not implemented'
  end
end
