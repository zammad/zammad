# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ObjectManager::Object do

  describe 'attribute permissions', db_strategy: :reset do

    let(:user) do
      create(:user, roles: [role_attribute_permissions])
    end
    let(:attribute) { described_class.new('Ticket').attributes(user).detect { |attribute| attribute[:name] == attribute_name } }

    let(:role_attribute_permissions) do
      create(:role).tap do |role|
        role.permission_grant('admin.organization')
        role.permission_grant('ticket.agent')
      end
    end

    let(:attribute_name) { 'example_attribute' }

    before do
      create(:object_manager_attribute_text, name: attribute_name, screens: screens)
      ObjectManager::Attribute.migration_execute
    end

    context 'when true and false values for show exist' do
      let(:screens) do
        {
          create: {
            'admin.organization': {
              shown: true
            },
            'ticket.agent':       {
              shown: false
            }
          }
        }
      end

      it 'uses true' do
        expect(attribute[:screen]['create']['shown']).to be true
      end
    end

    context 'when -all- is present' do
      let(:screens) do
        {
          create: {
            '-all-':              {
              shown: true
            },
            'admin.organization': {
              shown: false
            },
            'ticket.agent':       {
              shown: false
            }
          }
        }
      end

      it 'takes its values into account' do
        expect(attribute[:screen]['create']['shown']).to be true
      end
    end

    context 'when non boolean values are present' do
      let(:screens) do
        {
          create: {
            '-all-':              {
              shown:      true,
              item_class: 'column'
            },
            'admin.organization': {
              shown: false
            },
            'ticket.agent':       {
              shown: false
            }
          }
        }
      end

      it 'takes these values into account' do
        expect(attribute[:screen]['create']['item_class']).to eq('column')
      end
    end

    context 'when agent is also customer' do
      let(:user) { create(:agent_and_customer) }
      let(:screens) do
        {
          create: {
            'ticket.customer': {
              filter: [2, 4]
            },
            'ticket.agent':    {
              filter: [3, 5]
            }
          }
        }
      end

      it 'prefers agent over customer permissions' do
        expect(attribute[:screen]['create']['filter']).to eq([3, 5])
      end
    end
  end
end
