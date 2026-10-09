# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'ObjectManager Attributes', type: :request do

  let(:admin) do
    create(:admin)
  end

  describe 'request handling' do

    it 'does add new ticket text object' do
      authenticated_as(admin)
      post '/api/v1/object_manager_attributes', params: {}, as: :json

      # token based on headers
      params = {
        name:        'test1',
        object:      'Ticket',
        display:     'Test 1',
        active:      true,
        data_type:   'input',
        data_option: {
          default:   'test',
          type:      'text',
          maxlength: 120
        },
        screens:     {
          create_middle: {
            'ticket.customer': {
              shown:      true,
              item_class: 'column'
            },
            'ticket.agent':    {
              shown:      true,
              item_class: 'column'
            }
          },
          edit:          {
            'ticket.customer': {
              shown: true
            },
            'ticket.agent':    {
              shown: true
            }
          }
        },
        id:          'c-196'
      }

      post '/api/v1/object_manager_attributes', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['null']).to be_truthy
      expect(json_response['data_option']['null']).to be(true)
      expect(json_response['name']).to eq('test1')
    end

    it 'does not add new ticket text object with empty display' do
      authenticated_as(admin)

      params = {
        name:        'test_empty_display',
        object:      'Ticket',
        display:     '',
        active:      true,
        data_type:   'input',
        data_option: {
          default:   'test',
          type:      'text',
          maxlength: 120
        },
        screens:     {},
        id:          'c-197'
      }

      post '/api/v1/object_manager_attributes', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(ObjectManager::Attribute.get(object: 'Ticket', name: 'test_empty_display')).to be_nil
    end

    it 'does add new ticket text object - no default' do
      authenticated_as(admin)
      post '/api/v1/object_manager_attributes', params: {}, as: :json

      # token based on headers
      params = {
        name:        'test2',
        object:      'Ticket',
        display:     'Test 2',
        active:      true,
        data_type:   'input',
        data_option: {
          type:      'text',
          maxlength: 120
        },
        screens:     {
          create_middle: {
            'ticket.customer': {
              shown:      true,
              item_class: 'column'
            },
            'ticket.agent':    {
              shown:      true,
              item_class: 'column'
            }
          },
          edit:          {
            'ticket.customer': {
              shown: true
            },
            'ticket.agent':    {
              shown: true
            }
          }
        },
        id:          'c-196'
      }

      post '/api/v1/object_manager_attributes', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['null']).to be_truthy
      expect(json_response['data_option']['null']).to be(true)
      expect(json_response['name']).to eq('test2')
    end

    it 'does update ticket text object', db_strategy: :reset do

      # add a new object
      object = create(:object_manager_attribute_text)

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to be(true)

      authenticated_as(admin)
      post "/api/v1/object_manager_attributes/#{object.id}", params: {}, as: :json

      # parameters for updating
      params = {
        name:        object.name,
        object:      'Ticket',
        display:     'Test 4',
        active:      true,
        data_type:   'input',
        data_option: {
          default:   'test',
          type:      'text',
          maxlength: 120
        },
        screens:     {
          create_middle: {
            'ticket.customer': {
              shown:      true,
              item_class: 'column'
            },
            'ticket.agent':    {
              shown:      true,
              item_class: 'column'
            }
          },
          edit:          {
            'ticket.customer': {
              shown: true
            },
            'ticket.agent':    {
              shown: true
            }
          }
        },
        id:          'c-196'
      }

      # update the object
      put "/api/v1/object_manager_attributes/#{object.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['null']).to be_truthy
      expect(json_response['name']).to eq(object.name)
      expect(json_response['display']).to eq('Test 4')
    end

    it 'does add new ticket boolean object' do
      authenticated_as(admin)
      post '/api/v1/object_manager_attributes', params: {}, as: :json

      # token based on headers
      params = {
        active:      true,
        data_option: {
          options: {
            false: 'no',
            true:  'yes'
          }
        },
        data_type:   'boolean',
        display:     'Boolean 2',
        id:          'c-200',
        name:        'bool2',
        object:      'Ticket',
        screens:     {
          create_middle: {
            'ticket.agent'    => {
              item_class: 'column',
              shown:      true
            },
            'ticket.customer' => {
              item_class: 'column',
              shown:      true
            }
          },
          edit:          {
            'ticket.agent'    => {
              shown: true
            },
            'ticket.customer' => {
              shown: true
            }
          }
        }
      }

      post '/api/v1/object_manager_attributes', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['null']).to be_truthy
      expect(json_response['data_option']['null']).to be(true)
      expect(json_response['name']).to eq('bool2')
    end

    it 'does add new user select object' do
      authenticated_as(admin)
      post '/api/v1/object_manager_attributes', params: {}, as: :json

      # token based on headers
      params = {
        active:      true,
        data_option: {
          options: {
            key1: 'foo'
          }
        },
        data_type:   'select',
        display:     'Test 5',
        id:          'c-204',
        name:        'test5',
        object:      'User',
        screens:     {
          create: {
            'admin.user'      => {
              shown: true
            },
            'ticket.agent'    => {
              shown: true
            },
            'ticket.customer' => {
              shown: true
            }
          },
          edit:   {
            'admin.user'   => {
              shown: true
            },
            'ticket.agent' => {
              shown: true
            }
          },
          view:   {
            'admin.user'      => {
              shown: true
            },
            'ticket.agent'    => {
              shown: true
            },
            'ticket.customer' => {
              shown: true
            }
          }
        }
      }

      post '/api/v1/object_manager_attributes', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['null']).to be_truthy
      expect(json_response['data_option']['null']).to be(true)
      expect(json_response['name']).to eq('test5')
    end

    it 'does update user select object', authenticated_as: -> { admin }, db_strategy: :reset do
      # add a new object
      object = create(:object_manager_attribute_text, object_name: 'User')

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to be(true)

      post "/api/v1/object_manager_attributes/#{object.id}", params: {}, as: :json

      # parameters for updating
      params = {
        active:      true,
        data_option: {
          options: {
            key1: 'foo',
            key2: 'bar'
          }
        },
        data_type:   'select',
        display:     'Test 7',
        id:          'c-204',
        name:        object.name,
        object:      'User',
        screens:     {
          create: {
            'admin.user'      => {
              shown: true
            },
            'ticket.agent'    => {
              shown: true
            },
            'ticket.customer' => {
              shown: true
            }
          },
          edit:   {
            'admin.user'   => {
              shown: true
            },
            'ticket.agent' => {
              shown: true
            }
          },
          view:   {
            'admin.user'      => {
              shown: true
            },
            'ticket.agent'    => {
              shown: true
            },
            'ticket.customer' => {
              shown: true
            }
          }
        }
      }

      # update the object
      put "/api/v1/object_manager_attributes/#{object.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['options']).to be_truthy
      expect(json_response['name']).to eq(object.name)
      expect(json_response['display']).to eq('Test 7')
    end

    it 'does converts string to boolean for default value for boolean data type with true (01)', db_strategy: :reset do
      params = {
        name:        "customerdescription#{SecureRandom.uuid.tr('-', '_')}",
        object:      'Ticket',
        display:     "custom description#{SecureRandom.uuid.tr('-', '_')}",
        active:      true,
        data_type:   'boolean',
        data_option: {
          options: {
            true:  '',
            false: '',
          },
          default: 'true',
          screens: {
            create_middle: {
              'ticket.customer': {
                shown:      true,
                item_class: 'column'
              },
              'ticket.agent':    {
                shown:      true,
                item_class: 'column'
              }
            },
            edit:          {
              'ticket.customer': {
                shown: true
              },
              'ticket.agent':    {
                shown: true
              }
            }
          }
        },
        id:          'c-201'
      }

      authenticated_as(admin)
      post '/api/v1/object_manager_attributes', params: params, as: :json

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to be(true)

      expect(response).to have_http_status(:created) # created

      expect(json_response).to be_truthy
      expect(json_response['data_option']['default']).to be_truthy
      expect(json_response['data_option']['default']).to be(true)
      expect(json_response['data_type']).to eq('boolean')
    end

    it 'does converts string to boolean for default value for boolean data type with false (02)', db_strategy: :reset do
      params = {
        name:        "customerdescription_#{SecureRandom.uuid.tr('-', '_')}",
        object:      'Ticket',
        display:     "custom description #{SecureRandom.uuid.tr('-', '_')}",
        active:      true,
        data_type:   'boolean',
        data_option: {
          options: {
            true:  '',
            false: '',
          },
          default: 'false',
          screens: {
            create_middle: {
              'ticket.customer': {
                shown:      true,
                item_class: 'column'
              },
              'ticket.agent':    {
                shown:      true,
                item_class: 'column'
              }
            },
            edit:          {
              'ticket.customer': {
                shown: true
              },
              'ticket.agent':    {
                shown: true
              }
            }
          }
        },
      }

      authenticated_as(admin)
      post '/api/v1/object_manager_attributes', params: params, as: :json

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to be(true)

      expect(response).to have_http_status(:created) # created

      expect(json_response).to be_truthy
      expect(json_response['data_option']['default']).to be_falsey
      expect(json_response['data_option']['default']).to be(false)
      expect(json_response['data_type']).to eq('boolean')
    end

    context 'when deleting an attribute referenced by another object', db_strategy: :reset do
      let(:attribute_name) { 'test_attribute_referenced' }
      let(:condition)      { { "ticket.#{attribute_name}" => { operator: 'contains', value: 'DUMMY' } } }

      before do
        create(:object_manager_attribute_text, object_name: 'Ticket', name: attribute_name)
        ObjectManager::Attribute.migration_execute
        authenticated_as(admin)
      end

      def delete_attribute(object_name)
        attribute = ObjectManager::Attribute.get(object: object_name, name: attribute_name)
        delete "/api/v1/object_manager_attributes/#{attribute.id}", as: :json
      end

      shared_examples 'refusing to delete the attribute' do |factory, reference_type|
        it 'refuses to delete the attribute' do
          reference = create(factory, condition:)
          delete_attribute('Ticket')

          expect(response).to have_http_status(:unprocessable_content)
          expect(json_response['error']).to include(reference_type, reference.name, 'cannot be deleted!')
          expect(ObjectManager::Attribute.get(object: 'Ticket', name: attribute_name)).to be_present
        end
      end

      context 'with an overview' do
        include_examples 'refusing to delete the attribute', :overview, 'Overview'
      end

      context 'with a trigger' do
        include_examples 'refusing to delete the attribute', :trigger, 'Trigger'
      end

      context 'with a scheduler' do
        include_examples 'refusing to delete the attribute', :job, 'Job'
      end

      context 'with a user attribute of the same name' do
        before do
          create(:object_manager_attribute_text, object_name: 'User', name: attribute_name)
          ObjectManager::Attribute.migration_execute
          create(:overview, condition:)
        end

        it 'deletes only the unreferenced user attribute' do
          delete_attribute('User')
          expect(response).to have_http_status(:ok)
          expect(ObjectManager::Attribute.get(object: 'User', name: attribute_name)).to have_attributes(to_delete: true)

          delete_attribute('Ticket')
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    it 'does verify if attribute type can not be changed (07)', db_strategy: :reset do

      params = {
        name:        "customerdescription_#{SecureRandom.uuid.tr('-', '_')}",
        object:      'Ticket',
        display:     "custom description #{SecureRandom.uuid.tr('-', '_')}",
        active:      true,
        data_type:   'boolean',
        data_option: {
          options: {
            true:  '',
            false: '',
          },
          default: 'false',
          screens: {
            create_middle: {
              'ticket.customer': {
                shown:      true,
                item_class: 'column'
              },
              'ticket.agent':    {
                shown:      true,
                item_class: 'column'
              }
            },
            edit:          {
              'ticket.customer': {
                shown: true
              },
              'ticket.agent':    {
                shown: true
              }
            }
          }
        },
      }

      authenticated_as(admin)
      post '/api/v1/object_manager_attributes', params: params, as: :json

      expect(response).to have_http_status(:created) # created

      expect(json_response).to be_truthy
      expect(json_response['data_option']['default']).to be_falsey
      expect(json_response['data_option']['default']).to be(false)
      expect(json_response['data_type']).to eq('boolean')

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to be(true)

      params['data_type'] = 'input'
      params['data_option'] = {
        default:   'test',
        type:      'text',
        maxlength: 120
      }

      put "/api/v1/object_manager_attributes/#{json_response['id']}", params: params, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response).to be_truthy
      expect(json_response['error']).to be_truthy

    end

    it 'does verify if attribute type can be changed (08)', db_strategy: :reset do

      params = {
        name:        "customerdescription_#{SecureRandom.uuid.tr('-', '_')}",
        object:      'Ticket',
        display:     "custom description #{SecureRandom.uuid.tr('-', '_')}",
        active:      true,
        data_type:   'input',
        data_option: {
          default:   'test',
          type:      'text',
          maxlength: 120,
        },
        screens:     {
          create_middle: {
            'ticket.customer': {
              shown:      true,
              item_class: 'column'
            },
            'ticket.agent':    {
              shown:      true,
              item_class: 'column'
            }
          },
          edit:          {
            'ticket.customer': {
              shown: true
            },
            'ticket.agent':    {
              shown: true
            }
          },
        },
      }

      authenticated_as(admin)
      post '/api/v1/object_manager_attributes', params: params, as: :json

      expect(response).to have_http_status(:created) # created

      expect(json_response).to be_truthy
      expect(json_response['data_option']['default']).to eq('test')
      expect(json_response['data_type']).to eq('input')

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to be(true)

      params['data_type'] = 'select'
      params['data_option'] = {
        default: 'fuu',
        options: {
          key1: 'foo',
          key2: 'fuu',
        }
      }

      put "/api/v1/object_manager_attributes/#{json_response['id']}", params: params, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['default']).to eq('test')
      expect(json_response['data_option_new']['default']).to eq('fuu')
      expect(json_response['data_type']).to eq('select')
    end

    it "doesn't let to update item that doesn't exist", authenticated_as: -> { admin } do
      params = {
        active:      true,
        data_option: {
          type:      'text',
          maxlength: 200
        },
        data_type:   'input',
        display:     'Test 7',
        name:        'attribute_that_doesnt_exist',
        object:      'User',
      }

      # update the object
      put '/api/v1/object_manager_attributes/abc', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(ObjectManager::Attribute.get(object: 'User', name: 'attribute_that_doesnt_exist')).to be_nil
    end

    context 'position handling', authenticated_as: -> { admin } do
      let(:base_params) do
        {
          name:        "customerdescription_#{SecureRandom.uuid.tr('-', '_')}",
          object:      'Ticket',
          display:     "custom description #{SecureRandom.uuid.tr('-', '_')}",
          active:      true,
          data_type:   'input',
          data_option: {
            default:   'test',
            type:      'text',
            maxlength: 120,
          },
        }
      end

      let(:new_attribute_id)     { json_response['id'] }
      let(:new_attribute_object) { ObjectManager::Attribute.find new_attribute_id }

      before { post '/api/v1/object_manager_attributes', params: params, as: :json }

      context 'when creating a new attribute' do
        let(:params) { base_params }

        context 'with no position attribute provided' do
          let(:maximum_position) do
            ObjectManager::Attribute
              .for_object(params[:object])
              .maximum(:position)
          end

          it 'defaults to the maximum available position' do
            expect(new_attribute_object.position).to eq maximum_position
          end
        end

        context 'with a position attribute given' do
          let(:position) { 50 }
          let(:params)   { base_params.merge(position: position) }

          it 'defaults to given position' do
            expect(new_attribute_object.position).to eq position
          end
        end
      end

      context 'when updating an existing attribute' do
        let(:alternative_position) { 123 }
        let(:alternative_display)  { 'another description' }
        let(:params)               { base_params }
        let(:alternative_params)   { base_params.merge(display: alternative_display) }

        before do
          new_attribute_object.update! position: alternative_position

          put "/api/v1/object_manager_attributes/#{new_attribute_id}", params: alternative_params, as: :json

          new_attribute_object.reload
        end

        # confirm that test build up was correct
        it 'request succeeds' do
          expect(new_attribute_object.display).to eq alternative_display
        end

        # https://github.com/zammad/zammad/issues/3044
        it 'position did not reset' do
          expect(new_attribute_object.position).to eq alternative_position
        end
      end
    end
  end
end
