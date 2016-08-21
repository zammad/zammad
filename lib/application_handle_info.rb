module ApplicationHandleInfo
  def self.current
    Thread.current[:application_handle] || 'unknown'
  end

  def self.current=(name)
    Thread.current[:application_handle] = name
  end
end
