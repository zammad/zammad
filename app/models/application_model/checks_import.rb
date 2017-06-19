# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::ChecksImport
  extend ActiveSupport::Concern

  included do
    before_create :check_attributes_protected
  end

  def check_attributes_protected

    import_class_list = ['Ticket', 'Ticket::Article', 'History', 'Ticket::State', 'Ticket::StateType', 'Ticket::Priority', 'Group', 'User', 'Role' ]

    # do noting, use id as it is
    return if !Setting.get('system_init_done')
    return if Setting.get('import_mode') && import_class_list.include?(self.class.to_s)
    return if !has_attribute?(:id)
    self[:id] = nil
    true
  end
end
