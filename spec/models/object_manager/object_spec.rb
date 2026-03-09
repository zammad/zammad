# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ObjectManager::Object do

  describe 'attribute permissions', db_strategy: :reset do
    let(:user)            { create(:user, roles: [role_attribute_permissions]) }
    let(:skip_permission) { false }
    let(:act_as_customer) { false }
    let(:attributes) do
      described_class
        .new('Ticket')
        .attributes(user, skip_permission:, act_as_customer:)
    end
    let(:attribute) { attributes.detect { |attribute| attribute[:name] == attribute_name } }

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

      context 'with skip_permission: true' do
        let(:skip_permission) { true }

        it 'uses true' do
          expect(attribute[:screen]['create']['shown']).to be true
        end
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

      context 'with skip_permission: true' do
        let(:skip_permission) { true }

        it 'takes its values into account' do
          expect(attribute[:screen]['create']['shown']).to be true
        end
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

      context 'with skip_permission: true' do
        let(:skip_permission) { true }

        it 'takes these values into account' do
          expect(attribute[:screen]['create']['item_class']).to eq('column')
        end
      end
    end

    describe 'act_as_customer' do
      let(:user) { create(:agent_and_customer) }
      let(:screens) do
        {
          create: {
            'ticket.customer': {
              shown: false
            },
            'ticket.agent':    {
              shown: true
            }
          }
        }
      end

      context 'with act_as_customer: false' do
        it 'takes agent value' do
          expect(attribute[:screen]['create']['shown']).to be_truthy
        end

        context 'with a customer-only' do
          let(:user) { create(:customer) }

          it 'takes these values into account' do
            expect(attribute[:screen]['create']['shown']).to be_falsey
          end
        end
      end

      context 'with act_as_customer: true' do
        let(:act_as_customer) { true }

        it 'takes customer value' do
          expect(attribute[:screen]['create']['shown']).to be_falsey
        end

        context 'with an agent-only' do
          let(:user) { create(:agent) }

          it 'takes agent value' do
            expect(attribute[:screen]['create']['shown']).to be_truthy
          end
        end

        context 'with a customer-only' do
          let(:user) { create(:customer) }

          it 'takes customer value' do
            expect(attribute[:screen]['create']['shown']).to be_falsey
          end
        end
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

      context 'with skip_permission: true' do
        let(:skip_permission) { true }

        it 'prefers agent over customer permissions' do
          expect(attribute[:screen]['create']['filter']).to eq([3, 5])
        end
      end

      context 'with act_as_customer: true' do
        let(:act_as_customer) { true }

        it 'prefers customer over agent permissions' do
          expect(attribute[:screen]['create']['filter']).to eq([2, 4])
        end
      end
    end

    describe 'with ticket record and shared organization' do
      let(:organization) { create(:organization, shared: true) }
      let(:user)         { create(:customer, organization: organization) }
      let(:other_customer) { create(:customer, organization: organization) }
      let(:ticket)       { create(:ticket, customer: other_customer) }
      let(:attributes) do
        described_class
          .new('Ticket')
          .attributes(user, ticket, skip_permission:, act_as_customer:)
      end
      let(:screens) do
        {
          edit: {
            'ticket.customer': {
              shown: true
            },
          }
        }
      end

      let(:data_option) do
        {
          permission: ['ticket.agent', 'ticket.customer'],
        }
      end

      before do
        create(:object_manager_attribute_text, name: attribute_name, screens: screens, data_option: data_option)
        ObjectManager::Attribute.migration_execute
      end

      context 'when customer views own ticket' do
        let(:ticket) { create(:ticket, customer: user) }

        it 'includes customer-permissioned attributes' do
          expect(attribute).to be_present
        end

        it 'applies ticket.customer screen options' do
          expect(attribute[:screen]['edit']['shown']).to be true
        end
      end

      context 'when customer views shared organization ticket' do
        it 'includes customer-permissioned attributes' do
          expect(attribute).to be_present
        end

        it 'applies ticket.customer screen options' do
          expect(attribute[:screen]['edit']['shown']).to be true
        end
      end

      context 'when organization is not shared' do
        let(:organization) { create(:organization, shared: false) }

        it 'does not include customer-permissioned attributes' do
          expect(attribute).to be_nil
        end
      end

      context 'when customer is not in the same organization' do
        let(:other_organization) { create(:organization, shared: true) }
        let(:other_customer) { create(:customer, organization: other_organization) }

        it 'does not include customer-permissioned attributes' do
          expect(attribute).to be_nil
        end
      end
    end
  end
end
