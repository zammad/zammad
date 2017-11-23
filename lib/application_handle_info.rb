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
end
