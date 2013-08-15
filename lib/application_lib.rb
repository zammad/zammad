class ApplicationLib
  def self.load_adapter_by_setting(setting)
    adapter = Setting.get( setting )
    return if !adapter

    # load backend
    self.load_adapter(adapter)
  end
  def self.load_adapter(adapter)

    # load adapter
    backend = Object.const_get(adapter)

    # return backend
    return backend
  end
end
