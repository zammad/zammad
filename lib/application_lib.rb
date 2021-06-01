# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
      return if adapter.blank?

      adapter.constantize
    end
  end
end
