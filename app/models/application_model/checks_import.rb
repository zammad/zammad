# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::ChecksImport
  extend ActiveSupport::Concern

  included do
    before_create :check_attributes_protected
  end

  class_methods do
    # Use `include CanBeImported` in a class to override this method
    def importable?
      false
    end
  end

  def check_attributes_protected
    # do noting, use id as it is
    return if !Setting.get('system_init_done')
    return if Setting.get('import_mode') && self.class.importable?
    return if !has_attribute?(:id)

    self[:id] = nil
    true
  end
end
