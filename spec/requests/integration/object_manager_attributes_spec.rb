require 'rails_helper'

RSpec.describe 'ObjectManager Attributes', type: :request do

  let(:admin_user) do
    create(:admin_user)
  end

  describe 'request handling' do

    it 'does add new ticket text object' do
      authenticated_as(admin_user)
      post '/api/v1/object_manager_attributes', params: {}, as: :json

      # token based on headers
      params = {
        'name':        'test1',
        'object':      'Ticket',
        'display':     'Test 1',
        'active':      true,
        'data_type':   'input',
        'data_option': {
          'default':   'test',
          'type':      'text',
          'maxlength': 120
        },
        'screens':     {
          'create_middle': {
            'ticket.customer': {
              'shown':      true,
              'item_class': 'column'
            },
            'ticket.agent':    {
              'shown':      true,
              'item_class': 'column'
            }
          },
          'edit':          {
            'ticket.customer': {
              'shown': true
            },
            'ticket.agent':    {
              'shown': true
            }
          }
        },
        'id':          'c-196'
      }

      post '/api/v1/object_manager_attributes', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['null']).to be_truthy
      expect(json_response['data_option']['null']).to eq(true)
      expect(json_response['name']).to eq('test1')
    end

    it 'does add new ticket text object - no default' do
      authenticated_as(admin_user)
      post '/api/v1/object_manager_attributes', params: {}, as: :json

      # token based on headers
      params = {
        'name':        'test2',
        'object':      'Ticket',
        'display':     'Test 2',
        'active':      true,
        'data_type':   'input',
        'data_option': {
          'type':      'text',
          'maxlength': 120
        },
        'screens':     {
          'create_middle': {
            'ticket.customer': {
              'shown':      true,
              'item_class': 'column'
            },
            'ticket.agent':    {
              'shown':      true,
              'item_class': 'column'
            }
          },
          'edit':          {
            'ticket.customer': {
              'shown': true
            },
            'ticket.agent':    {
              'shown': true
            }
          }
        },
        'id':          'c-196'
      }

      post '/api/v1/object_manager_attributes', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['null']).to be_truthy
      expect(json_response['data_option']['null']).to eq(true)
      expect(json_response['name']).to eq('test2')
    end

    it 'does update ticket text object', db_strategy: :reset do

      # add a new object
      object = create(:object_manager_attribute_text)

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to eq(true)

      authenticated_as(admin_user)
      post "/api/v1/object_manager_attributes/#{object.id}", params: {}, as: :json

      # parameters for updating
      params = {
        'name':        'test4',
        'object':      'Ticket',
        'display':     'Test 4',
        'active':      true,
        'data_type':   'input',
        'data_option': {
          'default':   'test',
          'type':      'text',
          'maxlength': 120
        },
        'screens':     {
          'create_middle': {
            'ticket.customer': {
              'shown':      true,
              'item_class': 'column'
            },
            'ticket.agent':    {
              'shown':      true,
              'item_class': 'column'
            }
          },
          'edit':          {
            'ticket.customer': {
              'shown': true
            },
            'ticket.agent':    {
              'shown': true
            }
          }
        },
        'id':          'c-196'
      }

      # update the object
      put "/api/v1/object_manager_attributes/#{object.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['null']).to be_truthy
      expect(json_response['name']).to eq('test4')
      expect(json_response['display']).to eq('Test 4')
    end

    it 'does add new ticket boolean object' do
      authenticated_as(admin_user)
      post '/api/v1/object_manager_attributes', params: {}, as: :json

      # token based on headers
      params = {
        'active':      true,
        'data_option': {
          'options': {
            'false': 'no',
            'true':  'yes'
          }
        },
        'data_type':   'boolean',
        'display':     'Boolean 2',
        'id':          'c-200',
        'name':        'bool2',
        'object':      'Ticket',
        'screens':     {
          'create_middle': {
            'ticket.agent'    => {
              'item_class': 'column',
              'shown':      true
            },
            'ticket.customer' => {
              'item_class': 'column',
              'shown':      true
            }
          },
          'edit':          {
            'ticket.agent'    => {
              'shown': true
            },
            'ticket.customer' => {
              'shown': true
            }
          }
        }
      }

      post '/api/v1/object_manager_attributes', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['null']).to be_truthy
      expect(json_response['data_option']['null']).to eq(true)
      expect(json_response['name']).to eq('bool2')
    end

    it 'does add new user select object' do
      authenticated_as(admin_user)
      post '/api/v1/object_manager_attributes', params: {}, as: :json

      # token based on headers
      params = {
        'active':      true,
        'data_option': {
          'options': {
            'key1': 'foo'
          }
        },
        'data_type':   'select',
        'display':     'Test 5',
        'id':          'c-204',
        'name':        'test5',
        'object':      'User',
        'screens':     {
          'create': {
            'admin.user'      => {
              'shown': true
            },
            'ticket.agent'    => {
              'shown': true
            },
            'ticket.customer' => {
              'shown': true
            }
          },
          'edit':   {
            'admin.user'   => {
              'shown': true
            },
            'ticket.agent' => {
              'shown': true
            }
          },
          'view':   {
            'admin.user'      => {
              'shown': true
            },
            'ticket.agent'    => {
              'shown': true
            },
            'ticket.customer' => {
              'shown': true
            }
          }
        }
      }

      post '/api/v1/object_manager_attributes', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['null']).to be_truthy
      expect(json_response['data_option']['null']).to eq(true)
      expect(json_response['name']).to eq('test5')
    end

    it 'does update user select object', db_strategy: :reset do

      # add a new object
      object = create(:object_manager_attribute_text)

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to eq(true)

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
        name:        'test7',
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
      authenticated_as(admin_user)
      put "/api/v1/object_manager_attributes/#{object.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['options']).to be_truthy
      expect(json_response['name']).to eq('test7')
      expect(json_response['display']).to eq('Test 7')
    end

    it 'does converts string to boolean for default value for boolean data type with true (01)', db_strategy: :reset do
      params = {
        'name':        "customerdescription#{rand(999_999_999)}",
        'object':      'Ticket',
        'display':     "custom description#{rand(999_999_999)}",
        'active':      true,
        'data_type':   'boolean',
        'data_option': {
          'options': {
            'true':  '',
            'false': '',
          },
          'default': 'true',
          'screens': {
            'create_middle': {
              'ticket.customer': {
                'shown':      true,
                'item_class': 'column'
              },
              'ticket.agent':    {
                'shown':      true,
                'item_class': 'column'
              }
            },
            'edit':          {
              'ticket.customer': {
                'shown': true
              },
              'ticket.agent':    {
                'shown': true
              }
            }
          }
        },
        'id':          'c-201'
      }

      authenticated_as(admin_user)
      post '/api/v1/object_manager_attributes', params: params, as: :json

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to eq(true)

      expect(response).to have_http_status(:created) # created

      expect(json_response).to be_truthy
      expect(json_response['data_option']['default']).to be_truthy
      expect(json_response['data_option']['default']).to eq(true)
      expect(json_response['data_type']).to eq('boolean')
    end

    it 'does converts string to boolean for default value for boolean data type with false (02)', db_strategy: :reset do
      params = {
        'name':        "customerdescription_#{rand(999_999_999)}",
        'object':      'Ticket',
        'display':     "custom description #{rand(999_999_999)}",
        'active':      true,
        'data_type':   'boolean',
        'data_option': {
          'options': {
            'true':  '',
            'false': '',
          },
          'default': 'false',
          'screens': {
            'create_middle': {
              'ticket.customer': {
                'shown':      true,
                'item_class': 'column'
              },
              'ticket.agent':    {
                'shown':      true,
                'item_class': 'column'
              }
            },
            'edit':          {
              'ticket.customer': {
                'shown': true
              },
              'ticket.agent':    {
                'shown': true
              }
            }
          }
        },
      }

      authenticated_as(admin_user)
      post '/api/v1/object_manager_attributes', params: params, as: :json

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to eq(true)

      expect(response).to have_http_status(:created) # created

      expect(json_response).to be_truthy
      expect(json_response['data_option']['default']).to be_falsey
      expect(json_response['data_option']['default']).to eq(false)
      expect(json_response['data_type']).to eq('boolean')
    end

    it 'does ticket attributes cannot be removed when it is referenced by an overview (03)', db_strategy: :reset do

      # 1. create a new ticket attribute and execute migration
      ObjectManager::Attribute.migration_execute

      params = {
        'name':        'test_attribute_referenced_by_an_overview',
        'object':      'Ticket',
        'display':     'Test Attribute',
        'active':      true,
        'data_type':   'input',
        'data_option': {
          'default':   '',
          'type':      'text',
          'maxlength': 120,
          'null':      true,
          'options':   {},
          'relation':  ''
        },
        'screens':     {
          'create_middle': {
            'ticket.customer': {
              'shown':      true,
              'item_class': 'column'
            },
            'ticket.agent':    {
              'shown':      true,
              'item_class': 'column'
            }
          },
          'edit':          {
            'ticket.customer': {
              'shown': true
            },
            'ticket.agent':    {
              'shown': true
            }
          }
        },
      }

      authenticated_as(admin_user)
      post '/api/v1/object_manager_attributes', params: params, as: :json

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to eq(true)

      # 2. create an overview that uses the attribute
      params = {
        name:      'test_overview',
        roles:     Role.where(name: 'Agent').pluck(:name),
        condition: {
          'ticket.state_id':                                 {
            'operator': 'is',
            'value':    Ticket::State.all.pluck(:id),
          },
          'ticket.test_attribute_referenced_by_an_overview': {
            'operator': 'contains',
            'value':    'DUMMY'
          },
        },
        order:     {
          by:        'created_at',
          direction: 'DESC',
        },
        view:      {
          d:                 %w[title customer state created_at],
          s:                 %w[number title customer state created_at],
          m:                 %w[number title customer state created_at],
          view_mode_default: 's',
        },
        user_ids:  [ '1' ],
      }

      if Overview.where('name like ?', '%test%').empty?
        post '/api/v1/overviews', params: params, as: :json
        expect(response).to have_http_status(:created)
        expect(Hash).to eq(json_response.class)
        expect('test_overview').to eq(json_response['name'])
      end

      # 3. attempt to delete the ticket attribute
      get '/api/v1/object_manager_attributes', as: :json
      expect(response).to have_http_status(:ok)
      target_attribute = json_response.select { |x| x['name'] == 'test_attribute_referenced_by_an_overview' && x['object'] == 'Ticket' }
      expect(target_attribute.size).to eq(1)
      target_id = target_attribute[0]['id']

      delete "/api/v1/object_manager_attributes/#{target_id}", as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Overview')
      expect(response.body).to include('test_overview')
      expect(response.body).to include('cannot be deleted!')
    end

    it 'does ticket attributes cannot be removed when it is referenced by a trigger (04)', db_strategy: :reset do

      # 1. create a new ticket attribute and execute migration
      ObjectManager::Attribute.migration_execute

      params = {
        'name':        'test_attribute_referenced_by_a_trigger',
        'object':      'Ticket',
        'display':     'Test Attribute',
        'active':      true,
        'data_type':   'input',
        'data_option': {
          'default':   '',
          'type':      'text',
          'maxlength': 120,
          'null':      true,
          'options':   {},
          'relation':  ''
        },
        'screens':     {
          'create_middle': {
            'ticket.customer': {
              'shown':      true,
              'item_class': 'column'
            },
            'ticket.agent':    {
              'shown':      true,
              'item_class': 'column'
            }
          },
          'edit':          {
            'ticket.customer': {
              'shown': true
            },
            'ticket.agent':    {
              'shown': true
            }
          }
        },
      }

      authenticated_as(admin_user)
      post '/api/v1/object_manager_attributes', params: params, as: :json

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to eq(true)

      # 2. create an trigger that uses the attribute
      params = {
        name:      'test_trigger',
        condition: {
          'ticket.test_attribute_referenced_by_a_trigger': {
            'operator': 'contains',
            'value':    'DUMMY'
          }
        },
        'perform': {
          'ticket.state_id': {
            'value': '2'
          }
        },
        'active':  true,
        'id':      'c-3'
      }

      if Trigger.where('name like ?', '%test%').empty?
        post '/api/v1/triggers', params: params, as: :json
        expect(response).to have_http_status(:created)
        expect(Hash).to eq(json_response.class)
        expect('test_trigger').to eq(json_response['name'])
      end

      # 3. attempt to delete the ticket attribute
      get '/api/v1/object_manager_attributes', as: :json
      expect(response).to have_http_status(:ok)
      target_attribute = json_response.select { |x| x['name'] == 'test_attribute_referenced_by_a_trigger' && x['object'] == 'Ticket' }
      expect(target_attribute.size).to eq(1)
      target_id = target_attribute[0]['id']

      delete "/api/v1/object_manager_attributes/#{target_id}", as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Trigger')
      expect(response.body).to include('test_trigger')
      expect(response.body).to include('cannot be deleted!')
    end

    it 'does ticket attributes cannot be removed when it is referenced by a scheduler (05)', db_strategy: :reset do

      # 1. create a new ticket attribute and execute migration
      ObjectManager::Attribute.migration_execute

      params = {
        'name':        'test_attribute_referenced_by_a_scheduler',
        'object':      'Ticket',
        'display':     'Test Attribute',
        'active':      true,
        'data_type':   'input',
        'data_option': {
          'default':   '',
          'type':      'text',
          'maxlength': 120,
          'null':      true,
          'options':   {},
          'relation':  ''
        },
        'screens':     {
          'create_middle': {
            'ticket.customer': {
              'shown':      true,
              'item_class': 'column'
            },
            'ticket.agent':    {
              'shown':      true,
              'item_class': 'column'
            }
          },
          'edit':          {
            'ticket.customer': {
              'shown': true
            },
            'ticket.agent':    {
              'shown': true
            }
          }
        },
      }

      authenticated_as(admin_user)
      post '/api/v1/object_manager_attributes', params: params, as: :json

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to eq(true)

      # 2. create a scheduler that uses the attribute
      params = {
        name:                   'test_scheduler',
        'timeplan':             {
          'days':    {
            'Mon': true,
            'Tue': false,
            'Wed': false,
            'Thu': false,
            'Fri': false,
            'Sat': false,
            'Sun': false
          },
          'hours':   {
            '0':  true,
            '1':  false,
            '2':  false,
            '3':  false,
            '4':  false,
            '5':  false,
            '6':  false,
            '7':  false,
            '8':  false,
            '9':  false,
            '10': false,
            '11': false,
            '12': false,
            '13': false,
            '14': false,
            '15': false,
            '16': false,
            '17': false,
            '18': false,
            '19': false,
            '20': false,
            '21': false,
            '22': false,
            '23': false
          },
          'minutes': {
            '0':  true,
            '10': false,
            '20': false,
            '30': false,
            '40': false,
            '50': false
          }
        },
        'condition':            {
          'ticket.test_attribute_referenced_by_a_scheduler': {
            'operator': 'contains',
            'value':    'DUMMY'
          }
        },
        'perform':              {
          'ticket.state_id': {
            'value': '2'
          }
        },
        'disable_notification': true,
        'note':                 '',
        'active':               true,
        'id':                   'c-0'
      }

      if Job.where('name like ?', '%test%').empty?
        post '/api/v1/jobs', params: params, as: :json
        expect(response).to have_http_status(:created)
        expect(Hash).to eq(json_response.class)
        expect('test_scheduler').to eq(json_response['name'])
      end

      # 3. attempt to delete the ticket attribute
      get '/api/v1/object_manager_attributes', as: :json
      expect(response).to have_http_status(:ok)
      target_attribute = json_response.select { |x| x['name'] == 'test_attribute_referenced_by_a_scheduler' && x['object'] == 'Ticket' }
      expect(target_attribute.size).to eq(1)
      target_id = target_attribute[0]['id']

      delete "/api/v1/object_manager_attributes/#{target_id}", as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Job')
      expect(response.body).to include('test_scheduler')
      expect(response.body).to include('cannot be deleted!')
    end

    it 'does ticket attributes can be removed when it is referenced by an overview but by user object (06)', db_strategy: :reset do

      # 1. create a new ticket attribute and execute migration
      ObjectManager::Attribute.migration_execute

      params = {
        'name':        'test_attribute_referenced_by_an_overview',
        'object':      'Ticket',
        'display':     'Test Attribute',
        'active':      true,
        'data_type':   'input',
        'data_option': {
          'default':   '',
          'type':      'text',
          'maxlength': 120,
          'null':      true,
          'options':   {},
          'relation':  ''
        },
        'screens':     {
          'create_middle': {
            'ticket.customer': {
              'shown':      true,
              'item_class': 'column'
            },
            'ticket.agent':    {
              'shown':      true,
              'item_class': 'column'
            }
          },
          'edit':          {
            'ticket.customer': {
              'shown': true
            },
            'ticket.agent':    {
              'shown': true
            }
          }
        },
      }

      authenticated_as(admin_user)
      post '/api/v1/object_manager_attributes', params: params, as: :json

      params = {
        'name':        'test_attribute_referenced_by_an_overview',
        'object':      'User',
        'display':     'Test Attribute',
        'active':      true,
        'data_type':   'input',
        'data_option': {
          'default':   '',
          'type':      'text',
          'maxlength': 120,
          'null':      true,
          'options':   {},
          'relation':  ''
        },
        'screens':     {
          'create_middle': {
            'ticket.customer': {
              'shown':      true,
              'item_class': 'column'
            },
            'ticket.agent':    {
              'shown':      true,
              'item_class': 'column'
            }
          },
          'edit':          {
            'ticket.customer': {
              'shown': true
            },
            'ticket.agent':    {
              'shown': true
            }
          }
        },
      }

      post '/api/v1/object_manager_attributes', params: params, as: :json

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to eq(true)

      # 2. create an overview that uses the attribute
      params = {
        name:      'test_overview',
        roles:     Role.where(name: 'Agent').pluck(:name),
        condition: {
          'ticket.state_id':                                 {
            'operator': 'is',
            'value':    Ticket::State.all.pluck(:id),
          },
          'ticket.test_attribute_referenced_by_an_overview': {
            'operator': 'contains',
            'value':    'DUMMY'
          },
        },
        order:     {
          by:        'created_at',
          direction: 'DESC',
        },
        view:      {
          d:                 %w[title customer state created_at],
          s:                 %w[number title customer state created_at],
          m:                 %w[number title customer state created_at],
          view_mode_default: 's',
        },
        user_ids:  [ '1' ],
      }

      if Overview.where('name like ?', '%test%').empty?
        post '/api/v1/overviews', params: params, as: :json
        expect(response).to have_http_status(:created)
        expect(Hash).to eq(json_response.class)
        expect('test_overview').to eq(json_response['name'])
      end

      # 3. attempt to delete the ticket attribute
      get '/api/v1/object_manager_attributes', as: :json
      expect(response).to have_http_status(:ok)
      all_json_response = json_response

      target_attribute = all_json_response.select { |x| x['name'] == 'test_attribute_referenced_by_an_overview' && x['object'] == 'User' }
      expect(target_attribute.size).to eq(1)
      target_id = target_attribute[0]['id']

      delete "/api/v1/object_manager_attributes/#{target_id}", as: :json
      expect(response).to have_http_status(:ok)

      target_attribute = all_json_response.select { |x| x['name'] == 'test_attribute_referenced_by_an_overview' && x['object'] == 'Ticket' }
      expect(target_attribute.size).to eq(1)
      target_id = target_attribute[0]['id']

      delete "/api/v1/object_manager_attributes/#{target_id}", as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Overview')
      expect(response.body).to include('test_overview')
      expect(response.body).to include('cannot be deleted!')

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to eq(true)
    end

    it 'does verify if attribute type can not be changed (07)', db_strategy: :reset do

      params = {
        'name':        "customerdescription_#{rand(999_999_999)}",
        'object':      'Ticket',
        'display':     "custom description #{rand(999_999_999)}",
        'active':      true,
        'data_type':   'boolean',
        'data_option': {
          'options': {
            'true':  '',
            'false': '',
          },
          'default': 'false',
          'screens': {
            'create_middle': {
              'ticket.customer': {
                'shown':      true,
                'item_class': 'column'
              },
              'ticket.agent':    {
                'shown':      true,
                'item_class': 'column'
              }
            },
            'edit':          {
              'ticket.customer': {
                'shown': true
              },
              'ticket.agent':    {
                'shown': true
              }
            }
          }
        },
      }

      authenticated_as(admin_user)
      post '/api/v1/object_manager_attributes', params: params, as: :json

      expect(response).to have_http_status(:created) # created

      expect(json_response).to be_truthy
      expect(json_response['data_option']['default']).to be_falsey
      expect(json_response['data_option']['default']).to eq(false)
      expect(json_response['data_type']).to eq('boolean')

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to eq(true)

      params['data_type'] = 'input'
      params['data_option'] = {
        'default':   'test',
        'type':      'text',
        'maxlength': 120
      }

      put "/api/v1/object_manager_attributes/#{json_response['id']}", params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_truthy
      expect(json_response['error']).to be_truthy

    end

    it 'does verify if attribute type can be changed (08)', db_strategy: :reset do

      params = {
        'name':        "customerdescription_#{rand(999_999_999)}",
        'object':      'Ticket',
        'display':     "custom description #{rand(999_999_999)}",
        'active':      true,
        'data_type':   'input',
        'data_option': {
          'default':   'test',
          'type':      'text',
          'maxlength': 120,
        },
        'screens':     {
          'create_middle': {
            'ticket.customer': {
              'shown':      true,
              'item_class': 'column'
            },
            'ticket.agent':    {
              'shown':      true,
              'item_class': 'column'
            }
          },
          'edit':          {
            'ticket.customer': {
              'shown': true
            },
            'ticket.agent':    {
              'shown': true
            }
          },
        },
      }

      authenticated_as(admin_user)
      post '/api/v1/object_manager_attributes', params: params, as: :json

      expect(response).to have_http_status(:created) # created

      expect(json_response).to be_truthy
      expect(json_response['data_option']['default']).to eq('test')
      expect(json_response['data_type']).to eq('input')

      migration = ObjectManager::Attribute.migration_execute
      expect(migration).to eq(true)

      params['data_type'] = 'select'
      params['data_option'] = {
        'default': 'fuu',
        'options': {
          'key1': 'foo',
          'key2': 'fuu',
        }
      }

      put "/api/v1/object_manager_attributes/#{json_response['id']}", params: params, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['default']).to eq('test')
      expect(json_response['data_option_new']['default']).to eq('fuu')
      expect(json_response['data_type']).to eq('select')
    end
  end
end
