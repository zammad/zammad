# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ApplicationHandleInfo
  # stores current application handler.
  # for example application_server, scheduler, websocket, postmaster...
  thread_mattr_accessor :current

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

  # stores action context
  # for example merge, twitter, telegram....
  # used to determine if custom attribute validation shall run
  thread_mattr_accessor :context

  def self.in_context(name)
    raise ArgumentError, 'requires a block' if !block_given?

    orig = context
    self.context = name
    yield
  ensure
    self.context = orig
  end

  def self.context_without_custom_attributes?
    %w[merge twitter telegram facebook form mail sms].include? context.to_s
  end
end
