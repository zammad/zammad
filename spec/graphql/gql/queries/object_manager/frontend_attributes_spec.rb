# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::ObjectManager::FrontendAttributes, type: :graphql do
  context 'when fetching frontend attributes' do
    let(:query) do
      <<~QUERY
        query objectManagerFrontendAttributes(
          $object: EnumObjectManagerObjects!
        ) {
          objectManagerFrontendAttributes(
            object: $object
          ) {
            attributes {
              name
              display
              dataType
              dataOption
              isInternal
            }
            screens {
              name
              attributes
            }
          }
        }
      QUERY
    end
    let(:variables)                { { object: object } }
    let(:expected_result_agent)    { nil }
    let(:expected_result_customer) { nil }

    shared_context 'when fetching frontend attributes as agent and customer' do
      context 'with an agent', authenticated_as: :user, db_strategy: :reset do
        let(:user) { create(:admin) }
        let(:object_attribute) do
          create(:object_manager_attribute_text, object_name: object, screens: { 'edit' => {
                   'ticket.agent'       => {
                     'shown'    => true,
                     'required' => true,
                   },
                   'admin.organization' => {
                     'shown'    => true,
                     'required' => true,
                   }
                 } }).tap do
            ObjectManager::Attribute.migration_execute
          end
        end

        it 'returns frontend object attributes' do
          gql.execute(query, variables: variables)
          expect(gql.result.data).to eq(expected_result_agent)
        end

        context 'with a shown attribute' do
          before do
            object_attribute
            gql.execute(query, variables: variables)
          end

          it 'does contain the shown attribute' do
            edit_screen_attributes = gql.result.data['screens'].find { |screen| screen['name'] == 'edit' }['attributes']

            expect(edit_screen_attributes).to include(object_attribute.name)
          end

          it 'does contain shown attribute which is not internal' do
            frontend_object_attribute = gql.result.data['attributes'].find { |attribute| attribute['name'] == object_attribute.name }

            expect(frontend_object_attribute['isInternal']).to be(false)
          end
        end

        context 'with a hidden attribute' do
          before do
            object_attribute
            object_attribute.update!(screens: { 'edit' => {
                                                  'ticket.agent'       => {
                                                    'shown'    => false,
                                                    'required' => false,
                                                  },
                                                  'admin.organization' => {
                                                    'shown'    => false,
                                                    'required' => false,
                                                  }
                                                },
                                                'view' => {
                                                  'ticket.agent'       => {
                                                    'shown'    => false,
                                                    'required' => false,
                                                  },
                                                  'admin.organization' => {
                                                    'shown'    => false,
                                                    'required' => false,
                                                  }
                                                } })

            gql.execute(query, variables: variables)
          end

          it 'does contain also the hidden attribute because core workflow is active for the screen (edit)' do
            edit_screen_attributes = gql.result.data['screens'].find { |screen| screen['name'] == 'edit' }['attributes']

            expect(edit_screen_attributes).to include(object_attribute.name)
          end

          it 'does not contain the hidden attribute because for the screen (view)' do
            edit_screen_attributes = gql.result.data['screens'].find { |screen| screen['name'] == 'view' }['attributes']

            expect(edit_screen_attributes).not_to include(object_attribute.name)
          end
        end
      end

      context 'with a customer', authenticated_as: :user do
        let(:user) { create(:customer) }

        it 'returns all object manager attributes' do
          gql.execute(query, variables: variables)
          expect(gql.result.data).to eq(expected_result_customer)
        end
      end
    end

    context 'with object "Organization"' do
      let(:object) { 'Organization' }
      let(:expected_result_agent) do
        {
          'attributes' => [
            {
              'name'       => 'name',
              'display'    => 'Name',
              'dataType'   => 'input',
              'dataOption' => { 'type'       => 'text',
                                'maxlength'  => 150,
                                'null'       => false,
                                'item_class' => 'formGroup--halfSize' },
              'isInternal' => true,
            },

            {
              'name'       => 'shared',
              'display'    => 'Shared organization',
              'dataType'   => 'boolean',
              'dataOption' => { 'null'       => true,
                                'default'    => true,
                                'note'       => "Customers in the organization can view each other's items.",
                                'item_class' => 'formGroup--halfSize',
                                'options'    => { 'true'  => 'yes',
                                                  'false' => 'no' },
                                'translate'  => true,
                                'permission' => ['admin.organization'] },
              'isInternal' => true,
            },

            {
              'name'       => 'domain_assignment',
              'display'    => 'Domain based assignment',
              'dataType'   => 'boolean',
              'dataOption' => { 'null'       => true,
                                'default'    => false,
                                'note'       => 'Assign users based on user domain.',
                                'item_class' => 'formGroup--halfSize',
                                'options'    => { 'true'  => 'yes',
                                                  'false' => 'no' },
                                'translate'  => true,
                                'permission' => ['admin.organization'] },
              'isInternal' => true,
            },

            {
              'name'       => 'domain',
              'display'    => 'Domain',
              'dataType'   => 'input',
              'dataOption' => { 'type'       => 'text',
                                'maxlength'  => 150,
                                'null'       => true,
                                'item_class' => 'formGroup--halfSize' },
              'isInternal' => true,
            },

            {
              'name'       => 'note',
              'display'    => 'Note',
              'dataType'   => 'richtext',
              'dataOption' => { 'type'      => 'text',
                                'maxlength' => 5000,
                                'no_images' => false,
                                'null'      => true,
                                'note'      => 'Notes are visible to agents only, never to customers.' },
              'isInternal' => true,
            },

            {
              'name'       => 'active',
              'display'    => 'Active',
              'dataType'   => 'active',
              'dataOption' => { 'null'       => true,
                                'default'    => true,
                                'permission' => ['admin.organization'] },
              'isInternal' => true,
            }
          ],
          'screens'    => [
            {
              'name'       => 'edit',
              'attributes' => %w[name shared domain_assignment domain note active],
            },
            {
              'name'       => 'create',
              'attributes' => %w[name shared domain_assignment domain note active],
            },
            {
              'name'       => 'view',
              'attributes' => %w[name shared domain_assignment domain note],
            }
          ],
        }
      end

      let(:expected_result_customer) do
        {
          'attributes' => [
            {
              'name'       => 'name',
              'display'    => 'Name',
              'dataType'   => 'input',
              'dataOption' => { 'type'       => 'text',
                                'maxlength'  => 150,
                                'null'       => false,
                                'item_class' => 'formGroup--halfSize' },
              'isInternal' => true,
            },

            {
              'name'       => 'domain',
              'display'    => 'Domain',
              'dataType'   => 'input',
              'dataOption' => { 'type'       => 'text',
                                'maxlength'  => 150,
                                'null'       => true,
                                'item_class' => 'formGroup--halfSize' },
              'isInternal' => true,
            },

            {
              'name'       => 'note',
              'display'    => 'Note',
              'dataType'   => 'richtext',
              'dataOption' => { 'type'      => 'text',
                                'maxlength' => 5000,
                                'no_images' => false,
                                'null'      => true,
                                'note'      => 'Notes are visible to agents only, never to customers.' },
              'isInternal' => true,
            },
          ],
          'screens'    => [
            {
              'name'       => 'edit',
              'attributes' => %w[name domain note],
            },
            {
              'name'       => 'create',
              'attributes' => %w[name domain note],
            },
            {
              'name'       => 'view',
              'attributes' => %w[name],
            }
          ]
        }
      end

      include_context 'when fetching frontend attributes as agent and customer'
    end

    context 'with object "Ticket"' do
      let(:object) { 'Ticket' }

      let(:expected_result_agent) do
        {
          'attributes' => [
            {
              'name'       => 'title',
              'display'    => 'Title',
              'dataType'   => 'input',
              'dataOption' => {
                'type'      => 'text',
                'maxlength' => 200,
                'null'      => false,
                'translate' => false
              },
              'isInternal' => true,
            },
            {
              'name'       => 'customer_id',
              'display'    => 'Customer',
              'dataType'   => 'user_autocompletion',
              'dataOption' => {
                'relation'       => 'User',
                'autocapitalize' => false,
                'multiple'       => false,
                'guess'          => true,
                'null'           => false,
                'limit'          => 200,
                'placeholder'    => 'Enter Person or Organization/Company',
                'minLengt'       => 2,
                'translate'      => false,
                'permission'     => ['ticket.agent'],
                'belongs_to'     => 'customer',
              },
              'isInternal' => true,
            },
            {
              'name'       => 'organization_id',
              'display'    => 'Organization',
              'dataType'   => 'autocompletion_ajax_customer_organization',
              'dataOption' => {
                'relation'       => 'Organization',
                'autocapitalize' => false,
                'multiple'       => false,
                'null'           => true,
                'translate'      => false,
                'permission'     => ['ticket.agent', 'ticket.customer'],
                'belongs_to'     => 'organization',
              },
              'isInternal' => true,
            },
            {
              'name'       => 'group_id',
              'display'    => 'Group',
              'dataType'   => 'select',
              'dataOption' => {
                'default'                  => '',
                'relation'                 => 'Group',
                'relation_condition'       => { 'access'=>'full' },
                'nulloption'               => true,
                'multiple'                 => false,
                'null'                     => false,
                'translate'                => false,
                'only_shown_if_selectable' => true,
                'permission'               => ['ticket.agent', 'ticket.customer'],
                'maxlength'                => 255,
                'belongs_to'               => 'group',
              },
              'isInternal' => true,
            },
            {
              'name'       => 'owner_id',
              'display'    => 'Owner',
              'dataType'   => 'select',
              'dataOption' => {
                'default'            => '',
                'relation'           => 'User',
                'relation_condition' => { 'roles'=>'Agent' },
                'nulloption'         => true,
                'multiple'           => false,
                'null'               => true,
                'translate'          => false,
                'permission'         => ['ticket.agent'],
                'maxlength'          => 255,
                'belongs_to'         => 'owner',
              },
              'isInternal' => true,
            },
            {
              'name'       => 'state_id',
              'display'    => 'State',
              'dataType'   => 'select',
              'dataOption' => {
                'relation'   => 'TicketState',
                'nulloption' => true,
                'multiple'   => false,
                'null'       => false,
                'default'    => 2,
                'translate'  => true,
                'filter'     => Ticket::State.by_category(:viewable).pluck(:id),
                'maxlength'  => 255,
                'belongs_to' => 'state',
              },
              'isInternal' => true,
            },
            {
              'name'       => 'pending_time',
              'display'    => 'Pending till',
              'dataType'   => 'datetime',
              'dataOption' => {
                'future'     => true,
                'past'       => false,
                'diff'       => nil,
                'null'       => true,
                'translate'  => true,
                'permission' => ['ticket.agent'],
              },
              'isInternal' => true,
            },
            {
              'name'       => 'priority_id',
              'display'    => 'Priority',
              'dataType'   => 'select',
              'dataOption' => {
                'relation'   => 'TicketPriority',
                'nulloption' => false,
                'multiple'   => false,
                'null'       => false,
                'default'    => 2,
                'translate'  => true,
                'maxlength'  => 255,
                'belongs_to' => 'priority',
              },
              'isInternal' => true,
            },
            {
              'name'       => 'tags',
              'display'    => 'Tags',
              'dataType'   => 'tag',
              'dataOption' => {
                'type'      => 'text',
                'null'      => true,
                'translate' => false
              },
              'isInternal' => true,
            }
          ],
          'screens'    => [
            {
              'attributes' => %w[title customer_id organization_id],
              'name'       => 'create_top'
            },
            {
              'attributes' => %w[group_id owner_id state_id pending_time priority_id],
              'name'       => 'edit'
            },
            {
              'attributes' => %w[group_id owner_id state_id pending_time priority_id],
              'name'       => 'create_middle'
            },
            {
              'attributes' => ['tags'],
              'name'       => 'create_bottom'
            }
          ]
        }
      end

      let(:expected_result_customer) do
        {
          'attributes' => [
            {
              'name'       => 'title',
              'display'    => 'Title',
              'dataType'   => 'input',
              'dataOption' => {
                'type'      => 'text',
                'maxlength' => 200,
                'null'      => false,
                'translate' => false
              },
              'isInternal' => true,
            },
            {
              'name'       => 'organization_id',
              'display'    => 'Organization',
              'dataType'   => 'autocompletion_ajax_customer_organization',
              'dataOption' => {
                'relation'       => 'Organization',
                'autocapitalize' => false,
                'multiple'       => false,
                'null'           => true,
                'translate'      => false,
                'permission'     => ['ticket.agent', 'ticket.customer'],
                'belongs_to'     => 'organization',
              },
              'isInternal' => true,
            },
            {
              'name'       => 'group_id',
              'display'    => 'Group',
              'dataType'   => 'select',
              'dataOption' => {
                'default'                  => '',
                'relation'                 => 'Group',
                'relation_condition'       => { 'access'=>'full' },
                'nulloption'               => true,
                'multiple'                 => false,
                'null'                     => false,
                'translate'                => false,
                'only_shown_if_selectable' => true,
                'permission'               => ['ticket.agent', 'ticket.customer'],
                'maxlength'                => 255,
                'belongs_to'               => 'group',
              },
              'isInternal' => true,
            },
            {
              'name'       => 'state_id',
              'display'    => 'State',
              'dataType'   => 'select',
              'dataOption' => {
                'relation'   => 'TicketState',
                'nulloption' => true,
                'multiple'   => false,
                'null'       => false,
                'default'    => 2,
                'translate'  => true,
                'filter'     => Ticket::State.by_category(:viewable).pluck(:id),
                'maxlength'  => 255,
                'belongs_to' => 'state',
              },
              'isInternal' => true,
            },
          ],
          'screens'    => [
            {
              'attributes' => %w[title organization_id],
              'name'       => 'create_top'
            },
            {
              'attributes' => ['state_id'],
              'name'       => 'edit'
            },
            {
              'attributes' => %w[group_id state_id],
              'name'       => 'create_middle'
            },
            {
              'attributes' => [],
              'name'       => 'create_bottom'
            }
          ]
        }
      end

      include_context 'when fetching frontend attributes as agent and customer'
    end
  end
end
