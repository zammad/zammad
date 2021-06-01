# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module EventBuffer

  def self.list(key)
    if !Thread.current[:event_buffer]
      Thread.current[:event_buffer] = {}
    end
    Thread.current[:event_buffer][key] || []
  end

  def self.add(key, item)
    if !Thread.current[:event_buffer]
      Thread.current[:event_buffer] = {}
    end
    if !Thread.current[:event_buffer][key]
      Thread.current[:event_buffer][key] = []
    end
    Thread.current[:event_buffer][key].push item
  end

  def self.reset(key)
    return if !Thread.current[:event_buffer]
    return if !Thread.current[:event_buffer][key]

    Thread.current[:event_buffer][key] = []
  end

end
