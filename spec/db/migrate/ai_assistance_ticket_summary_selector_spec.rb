# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AIAssistanceTicketSummarySelector, db_strategy: :reset, type: :db_migration do
  let(:attribute) { ObjectManager::Attribute.get(object: 'Group', name: 'summary_generation') }

  before do
    Setting.find_by(name: 'ai_assistance_ticket_summary_selector')&.destroy!

    options = attribute.data_option['options'].reject { |option| option['value'] == 'disabled' }
    options << { 'name' => 'Hide ticket summary sidebar', 'value' => 'disabled' }

    attribute.data_option['options'] = options
    attribute.save!
  end

  it 'creates the ticket summary selector setting' do
    expect { migrate }
      .to change { Setting.exists?(name: 'ai_assistance_ticket_summary_selector') }
      .to(true)
  end

  it 'removes the disabled option from the group summary generation attribute' do
    expect { migrate }
      .to change { attribute.reload.data_option['options'].any? { |option| option['value'] == 'disabled' } }
      .from(true)
      .to(false)
  end

  it 'resets disabled group summary generation values to global default' do
    group = create(:group, summary_generation: 'disabled')

    expect { migrate }
      .to change { group.reload.summary_generation }
      .from('disabled')
      .to('global_default')
  end
end
