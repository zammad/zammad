# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::ObjectManager::FrontendAttributes, type: :graphql do
  context 'when fetching meta information' do
    let(:query)                    { gql.read_files('shared/graphql/queries/objectManagerFrontendAttributes.graphql') }
    let(:variables)                { { object: object, filterScreen: filter_screen } }
    let(:filter_screen)            { nil }
    let(:expected_result_agent)    { nil }
    let(:expected_result_customer) { nil }

    before do
      gql.execute(query, variables: variables)
    end

    shared_context 'when fetching (filtered) meta information as agent and customer' do
      context 'with an agent', authenticated_as: :user, db_strategy: :reset do
        let(:user) { create(:admin) }

        it 'returns all object manager attributes' do
          expect(gql.result.data).to eq(expected_result_agent)
        end

        context 'with a specific screen', db_strategy: :reset do
          let(:screen) { 'edit' }
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

          before do
            object_attribute
            gql.execute(query, variables: variables)
          end

          context 'with a shown attribute' do
            it 'does contain the shown attribute' do

              expect(gql.result.data).to include(
                include(
                  'name' => object_attribute.name
                )
              )
            end
          end

          context 'with a hidden attribute' do
            before do
              object_attribute.update!(screens: { 'edit' => {
                                         'ticket.agent'       => {
                                           'shown'    => false,
                                           'required' => false,
                                         },
                                         'admin.organization' => {
                                           'shown'    => false,
                                           'required' => false,
                                         }
                                       } })
            end

            it 'does not contain the hidden attribute' do
              expect(gql.result.data).not_to include(
                {
                  'name' => object_attribute.name,
                }
              )
            end
          end
        end
      end

      context 'with a customer', authenticated_as: :user do
        let(:user) { create(:customer) }

        it 'returns all object manager attributes' do
          expect(gql.result.data).to eq(expected_result_customer)
        end
      end
    end

    context 'with object "Organization"' do
      let(:object) { 'Organization' }
      let(:expected_result_agent) do
        [
          {
            'name'       => 'name',
            'display'    => 'Name',
            'dataType'   => 'input',
            'dataOption' => { 'type'       => 'text',
                              'maxlength'  => 150,
                              'null'       => false,
                              'item_class' => 'formGroup--halfSize' }
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
                              'permission' => ['admin.organization'] }
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
                              'permission' => ['admin.organization'] }
          },

          {
            'name'       => 'domain',
            'display'    => 'Domain',
            'dataType'   => 'input',
            'dataOption' => { 'type'       => 'text',
                              'maxlength'  => 150,
                              'null'       => true,
                              'item_class' => 'formGroup--halfSize' }
          },

          {
            'name'       => 'note',
            'display'    => 'Note',
            'dataType'   => 'richtext',
            'dataOption' => { 'type'      => 'text',
                              'maxlength' => 5000,
                              'no_images' => false,
                              'null'      => true,
                              'note'      => 'Notes are visible to agents only, never to customers.' }
          },

          {
            'name'       => 'active',
            'display'    => 'Active',
            'dataType'   => 'active',
            'dataOption' => { 'null'       => true,
                              'default'    => true,
                              'permission' => ['admin.organization'] }
          }
        ]
      end

      let(:expected_result_customer) do
        [
          {
            'name'       => 'name',
            'display'    => 'Name',
            'dataType'   => 'input',
            'dataOption' => { 'type'       => 'text',
                              'maxlength'  => 150,
                              'null'       => false,
                              'item_class' => 'formGroup--halfSize' }
          },

          {
            'name'       => 'domain',
            'display'    => 'Domain',
            'dataType'   => 'input',
            'dataOption' => { 'type'       => 'text',
                              'maxlength'  => 150,
                              'null'       => true,
                              'item_class' => 'formGroup--halfSize' }
          },

          {
            'name'       => 'note',
            'display'    => 'Note',
            'dataType'   => 'richtext',
            'dataOption' => { 'type'      => 'text',
                              'maxlength' => 5000,
                              'no_images' => false,
                              'null'      => true,
                              'note'      => 'Notes are visible to agents only, never to customers.' }
          },
        ]
      end

      include_context 'when fetching (filtered) meta information as agent and customer'
    end

    context 'with object "Ticket"' do
      let(:object) { 'Ticket' }

      let(:expected_result_agent) do
        [
          {
            'name'       => 'number',
            'display'    => '#',
            'dataType'   => 'input',
            'dataOption' => {
              'type'      => 'text',
              'readonly'  => 1,
              'null'      => true,
              'maxlength' => 60,
              'width'     => '68px'
            }
          },
          {
            'name'       => 'title',
            'display'    => 'Title',
            'dataType'   => 'input',
            'dataOption' => {
              'type'      => 'text',
              'maxlength' => 200,
              'null'      => false,
              'translate' => false
            }
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
              'permission'     => ['ticket.agent']
            }
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
              'permission'     => ['ticket.agent', 'ticket.customer']
            }
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
              'maxlength'                => 255
            }
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
              'maxlength'          => 255
            }
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
              'maxlength'  => 255
            }
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
              'permission' => ['ticket.agent']
            }
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
              'maxlength'  => 255
            }
          },
          {
            'name'       => 'tags',
            'display'    => 'Tags',
            'dataType'   => 'tag',
            'dataOption' => {
              'type'      => 'text',
              'null'      => true,
              'translate' => false
            }
          }
        ]
      end

      let(:expected_result_customer) do
        [
          {
            'name'       => 'number',
            'display'    => '#',
            'dataType'   => 'input',
            'dataOption' => {
              'type'      => 'text',
              'readonly'  => 1,
              'null'      => true,
              'maxlength' => 60,
              'width'     => '68px'
            }
          },
          {
            'name'       => 'title',
            'display'    => 'Title',
            'dataType'   => 'input',
            'dataOption' => {
              'type'      => 'text',
              'maxlength' => 200,
              'null'      => false,
              'translate' => false
            }
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
              'permission'     => ['ticket.agent', 'ticket.customer']
            }
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
              'maxlength'                => 255
            }
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
              'maxlength'  => 255
            }
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
              'maxlength'  => 255
            }
          },
          {
            'name'       => 'tags',
            'display'    => 'Tags',
            'dataType'   => 'tag',
            'dataOption' => {
              'type'      => 'text',
              'null'      => true,
              'translate' => false
            }
          }
        ]
      end

      include_context 'when fetching (filtered) meta information as agent and customer'
    end
  end
end
