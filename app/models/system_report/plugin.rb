# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin
  include Mixin::RequiredSubPaths

  def self.list
    @list ||= descendants.sort_by(&:name)
  end

  def self.name_plugin
    name.sub('SystemReport::Plugin::', '')
  end

  def self.path
    name_plugin.split('::')
  end

  def initialize
    # TODO
  end

  def fetch
    raise NotImplementedError
  end
end
