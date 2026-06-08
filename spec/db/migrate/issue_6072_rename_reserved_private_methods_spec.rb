# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue6072RenameReservedPrivateMethods, db_strategy: :reset, type: :db_migration do
  before do
    original = Ticket.instance_method(:ai_action)
    Ticket.class_eval do
      undef_method :ai_action
    end
    create(:object_manager_attribute_text, object_name: 'Ticket', name: 'ai_action')
    ObjectManager::Attribute.migration_execute
    Ticket.class_eval do
      define_method(:ai_action, original)
      private :ai_action
    end
  end

  it 'does rename the reserved word data' do
    migrate
    expect(Ticket.column_names.include?('_ai_action')).to be(true)
  end
end
