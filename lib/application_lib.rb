module ApplicationLib
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

=begin

load adapter based on setting option

  result = self.load_adapter_by_setting('some_setting_with_class_name')

returns

  result = Some::Classname

=end

    def load_adapter_by_setting(setting)
      adapter = Setting.get(setting)
      return if !adapter
      return if adapter.empty?

      # load backend
      load_adapter(adapter)
    end

=begin

load adapter

  result = self.load_adapter('Some::Classname')

returns

  result = Some::Classname

=end

    def load_adapter(adapter)

      # load adapter

      # will only work on ruby 2.0
      #Object.const_get(adapter)

      # will work on ruby 1.9 and 2.0
      #adapter.split('::').inject(Object) do |mod, class_name|
      #    mod.const_get(class_name)
      #end

      # will work with active_support
      adapter = adapter.constantize

      if !adapter
        raise "Can't load adapter '#{adapter_name}'"
      end

      adapter
    end
  end
end
