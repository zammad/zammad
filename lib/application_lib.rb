class ApplicationLib

=begin

load adapter based on setting option

  adapter = self.load_adapter_by_setting( 'some_setting_with_class_name' )

returns

  result = adapter_class

=end

  def self.load_adapter_by_setting(setting)
    adapter = Setting.get( setting )
    return if !adapter

    # load backend
    self.load_adapter(adapter)
  end

=begin

load adapter

  adapter = self.load_adapter( 'some_class_name' )

returns

  result = adapter_class

=end

  def self.load_adapter(adapter)

    # load adapter
    Object.const_get(adapter)
  end
end
