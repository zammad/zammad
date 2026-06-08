# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ObjectManager::Object do

  describe 'attribute permissions', db_strategy: :reset do
    let(:user)            { create(:user, roles: [role_attribute_permissions]) }
    let(:skip_permission) { false }
    let(:act_as_customer) { false }
    let(:record)          { nil }
    let(:attributes) do
      described_class
        .new('Ticket')
        .attributes(user, record, skip_permission:, act_as_customer:)
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
      attr = build(:object_manager_attribute_text, name: attribute_name, screens: screens)
      attr.data_option.merge!(data_option) if defined?(data_option)
      attr.save!
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

    context 'with a ticket record' do
      let(:record) { create(:ticket) }

      let(:data_option) do
        {
          permission: ['ticket.agent', 'ticket.customer'],
        }
      end

      let(:screens) do
        {
          edit: {
            'ticket.agent':    {
              shown: true
            },
            'ticket.customer': {
              shown: true
            }
          }
        }
      end

      describe 'with an agent' do
        context 'when shown' do
          let(:user) { create(:agent, groups: [record.group]) }

          it 'applies ticket.agent screen options' do
            expect(attribute[:screen]['edit']['shown']).to be true
          end
        end

        context 'when not shown' do
          let(:user)  { create(:agent) }

          it 'does not include the attribute' do
            expect(attribute).to be_nil
          end
        end
      end

      describe 'with an agent-customer' do
        let(:group) { create(:group) }
        let(:user)  { create(:agent_and_customer, groups: [group]) }

        context 'when acts as an agent on the ticket' do
          let(:record) { create(:ticket, group:) }

          it 'applies ticket.agent screen options' do
            expect(attribute[:screen]['edit']['shown']).to be true
          end
        end

        context 'when acts as a customer on the ticket' do
          let(:record) { create(:ticket, customer: user) }

          it 'applies ticket.customer screen options' do
            expect(attribute[:screen]['edit']['shown']).to be true
          end
        end

        context 'when does not have access to the ticket' do
          let(:record) { create(:ticket) }

          it 'does not include the attribute' do
            expect(attribute).to be_nil
          end
        end
      end

      # https://github.com/zammad/zammad/issues/5993
      describe 'with a shared organization' do
        let(:organization)   { create(:organization, shared: true) }
        let(:user)           { create(:customer, organization: organization) }
        let(:other_customer) { create(:customer, organization: organization) }
        let(:record)         { create(:ticket, customer: other_customer, organization: organization) }

        context 'when customer views own ticket' do
          let(:record) { create(:ticket, customer: user) }

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
end
