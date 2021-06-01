# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationHandleInfo
  def self.current
    Thread.current[:application_handle] || 'unknown'
  end

  def self.current=(name)
    Thread.current[:application_handle] = name
  end

  def self.postmaster?
    return false if current.blank?

    current.split('.')[1] == 'postmaster'
  end

  def self.use(name)
    raise ArgumentError, 'requires a block' if !block_given?

    orig = current
    self.current = name
    yield
  ensure
    self.current = orig
  end
end
