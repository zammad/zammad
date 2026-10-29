# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ApplicationLib
  def self.included(base)
    base.extend(ClassMethods)
  end

=begin

load a class or module by name, but only one defined directly in the given namespace (the resolved
constant is checked, as a namespace also resolves the constants of its ancestors:
'Service::Image::ClassMethods' is ApplicationLib::ClassMethods)

  result = ApplicationLib.load_adapter('Service::Image::Zammad', namespace: Service::Image)

returns

  result = Service::Image::Zammad # or nil for any other constant

=end

  def self.load_adapter(name, namespace:)
    adapter = name.to_s.safe_constantize

    adapter if adapter.is_a?(Module) && adapter.module_parent == namespace
  end

=begin

load a class by name, but only a subclass of the given class

  result = ApplicationLib.load_subclass('Import::Ldap', base: Import::IntegrationBase)

returns

  result = Import::Ldap # or nil for any other constant

=end

  def self.load_subclass(name, base:)
    subclass = name.to_s.safe_constantize

    subclass if subclass.is_a?(Class) && subclass < base
  end

  module ClassMethods

=begin

load adapter based on setting option

  result = self.load_adapter_by_setting('some_setting_with_class_name')

returns

  result = Some::Classname # or nil if the setting is blank or names a constant not defined directly in self

=end

    def load_adapter_by_setting(setting)
      adapter = Setting.get(setting)
      return if adapter.blank?

      loaded = load_adapter(adapter)
      log_rejected_adapter(setting, adapter, loaded)

      loaded
    end

    def load_adapter(name)
      ApplicationLib.load_adapter(name, namespace: self)
    end

    private

    # This runs per request (e.g. per avatar lookup or login), so the same rejected value is logged
    #   once per process until the setting changes.
    def log_rejected_adapter(setting, adapter, loaded)
      @rejected_adapters ||= {}

      if loaded
        @rejected_adapters.delete(setting)
        return
      end

      return if @rejected_adapters[setting] == adapter

      @rejected_adapters[setting] = adapter
      Rails.logger.error "Setting '#{setting}' names '#{adapter}', which is not defined in #{name}; ignoring it."
    end
  end
end
