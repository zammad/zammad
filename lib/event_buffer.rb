module EventBuffer

  def self.list
    Thread.current[:event_buffer] || []
  end

  def self.add(item)
    if !Thread.current[:event_buffer]
      Thread.current[:event_buffer] = []
    end
    Thread.current[:event_buffer].push item
  end

  def self.reset
    Thread.current[:event_buffer] = []
  end

end
