require 'integration_test_helper'
require 'rake'

class ObjectManagerAttributesControllerTest < ActionDispatch::IntegrationTest

  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create_or_update(
      login: 'tickets-admin',
      firstname: 'Tickets',
      lastname: 'Admin',
      email: 'tickets-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

  end

  test 'add new ticket text object' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')

    post '/api/v1/object_manager_attributes', params: {}, headers: @headers
    token = @response.headers['CSRF-TOKEN']

    # token based on headers
    params = {
      'name': 'test1',
      'object': 'Ticket',
      'display': 'Test 1',
      'active': true,
      'data_type': 'input',
      'data_option': {
        'default': 'test',
        'type': 'text',
        'maxlength': 120
      },
      'screens': {
        'create_middle': {
          'ticket.customer': {
            'shown': true,
            'item_class': 'column'
          },
          'ticket.agent': {
            'shown': true,
            'item_class': 'column'
          }
        },
        'edit': {
          'ticket.customer': {
            'shown': true
          },
          'ticket.agent': {
            'shown': true
          }
        }
      },
      'id': 'c-196'
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    assert(result['data_option']['null'])
    assert_equal(result['data_option']['null'], true)
    assert_equal(result['name'], 'test1')
  end

  test 'add new ticket text object - no default' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')

    post '/api/v1/object_manager_attributes', params: {}, headers: @headers
    token = @response.headers['CSRF-TOKEN']

    # token based on headers
    params = {
      'name': 'test2',
      'object': 'Ticket',
      'display': 'Test 2',
      'active': true,
      'data_type': 'input',
      'data_option': {
        'type': 'text',
        'maxlength': 120
      },
      'screens': {
        'create_middle': {
          'ticket.customer': {
            'shown': true,
            'item_class': 'column'
          },
          'ticket.agent': {
            'shown': true,
            'item_class': 'column'
          }
        },
        'edit': {
          'ticket.customer': {
            'shown': true
          },
          'ticket.agent': {
            'shown': true
          }
        }
      },
      'id': 'c-196'
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    assert(result['data_option']['null'])
    assert_equal(result['data_option']['null'], true)
    assert_equal(result['name'], 'test2')
  end

  test 'update ticket text object' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')

    # add a new object
    object = ObjectManager::Attribute.add(
      name: 'test3',
      object: 'Ticket',
      display: 'Test 3',
      active: true,
      data_type: 'input',
      data_option: {
        default: 'test',
        type: 'text',
        maxlength: 120,
        null: true
      },
      screens: {
        create_middle: {
          'ticket.customer' => {
            shown: true,
            item_class: 'column'
          },
          'ticket.agent' => {
            shown: true,
            item_class: 'column'
          }
        },
        edit: {
          'ticket.customer' => {
            shown: true
          },
          'ticket.agent' => {
            shown: true
          }
        }
      },
      position: 1550,
      editable: true
    )

    migration = ObjectManager::Attribute.migration_execute
    assert_equal(migration, true)

    post "/api/v1/object_manager_attributes/#{object.id}", params: {}, headers: @headers
    token = @response.headers['CSRF-TOKEN']

    # parameters for updating
    params = {
      'name': 'test4',
      'object': 'Ticket',
      'display': 'Test 4',
      'active': true,
      'data_type': 'input',
      'data_option': {
        'default': 'test',
        'type': 'text',
        'maxlength': 120
      },
      'screens': {
        'create_middle': {
          'ticket.customer': {
            'shown': true,
            'item_class': 'column'
          },
          'ticket.agent': {
            'shown': true,
            'item_class': 'column'
          }
        },
        'edit': {
          'ticket.customer': {
            'shown': true
          },
          'ticket.agent': {
            'shown': true
          }
        }
      },
      'id': 'c-196'
    }

    # update the object
    put "/api/v1/object_manager_attributes/#{object.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert(result['data_option']['null'])
    assert_equal(result['name'], 'test4')
    assert_equal(result['display'], 'Test 4')
  end

  test 'add new ticket boolean object' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')

    post '/api/v1/object_manager_attributes', params: {}, headers: @headers
    token = @response.headers['CSRF-TOKEN']

    # token based on headers
    params = {
      'active': true,
      'data_option': {
        'options': {
          'false': 'no',
          'true': 'yes'
        }
      },
      'data_type': 'boolean',
      'display': 'Boolean 2',
      'id': 'c-200',
      'name': 'bool2',
      'object': 'Ticket',
      'screens': {
        'create_middle': {
          'ticket.agent' => {
            'item_class': 'column',
            'shown': true
          },
          'ticket.customer' => {
            'item_class': 'column',
            'shown': true
          }
        },
        'edit': {
          'ticket.agent' => {
            'shown': true
          },
          'ticket.customer' => {
            'shown': true
          }
        }
      }
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    assert(result['data_option']['null'])
    assert_equal(result['data_option']['null'], true)
    assert_equal(result['name'], 'bool2')
  end

  test 'add new user select object' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')

    post '/api/v1/object_manager_attributes', params: {}, headers: @headers
    token = @response.headers['CSRF-TOKEN']

    # token based on headers
    params = {
      'active': true,
      'data_option': {
        'options': {
          'key1': 'foo'
        }
      },
      'data_type': 'select',
      'display': 'Test 5',
      'id': 'c-204',
      'name': 'test5',
      'object': 'User',
      'screens': {
        'create': {
          'admin.user' => {
            'shown': true
          },
          'ticket.agent' => {
            'shown': true
          },
          'ticket.customer' => {
            'shown': true
          }
        },
        'edit': {
          'admin.user' => {
            'shown': true
          },
          'ticket.agent' => {
            'shown': true
          }
        },
        'view': {
          'admin.user' => {
            'shown': true
          },
          'ticket.agent' => {
            'shown': true
          },
          'ticket.customer' => {
            'shown': true
          }
        }
      }
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    assert(result['data_option']['null'])
    assert_equal(result['data_option']['null'], true)
    assert_equal(result['name'], 'test5')
  end

  test 'update user select object' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')

    # add a new object
    object = ObjectManager::Attribute.add(
      active: true,
      data_option: {
        options: {
          key1: 'foo'
        },
        null: true,
        default: '',
      },
      data_type: 'select',
      display: 'Test 6',
      id: 'c-204',
      name: 'test6',
      object: 'User',
      screens: {
        create: {
          'admin.user' => {
            shown: true
          },
          'ticket.agent' => {
            shown: true
          },
          'ticket.customer' => {
            shown: true
          }
        },
        edit: {
          'admin.user' => {
            shown: true
          },
          'ticket.agent' => {
            shown: true
          }
        },
        view: {
          'admin.user' => {
            shown: true
          },
          'ticket.agent' => {
            shown: true
          },
          'ticket.customer' => {
            shown: true
          }
        }
      },
      position: 1550,
      editable: true
    )

    migration = ObjectManager::Attribute.migration_execute
    assert_equal(migration, true)

    post "/api/v1/object_manager_attributes/#{object.id}", params: {}, headers: @headers
    token = @response.headers['CSRF-TOKEN']

    # parameters for updating
    params = {
      active: true,
      data_option: {
        options: {
          key1: 'foo',
          key2: 'bar'
        }
      },
      data_type: 'select',
      display: 'Test 7',
      id: 'c-204',
      name: 'test7',
      object: 'User',
      screens: {
        create: {
          'admin.user' => {
            shown: true
          },
          'ticket.agent' => {
            shown: true
          },
          'ticket.customer' => {
            shown: true
          }
        },
        edit: {
          'admin.user' => {
            shown: true
          },
          'ticket.agent' => {
            shown: true
          }
        },
        view: {
          'admin.user' => {
            shown: true
          },
          'ticket.agent' => {
            shown: true
          },
          'ticket.customer' => {
            shown: true
          }
        }
      }
    }

    # update the object
    put "/api/v1/object_manager_attributes/#{object.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert(result['data_option']['options'])
    assert_equal(result['name'], 'test7')
    assert_equal(result['display'], 'Test 7')
  end

  test '01 converts string to boolean for default value for boolean data type with true' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin@example.com', 'adminpw')

    params = {
      'name': "customerdescription#{rand(999_999_999)}",
      'object': 'Ticket',
      'display': "custom description#{rand(999_999_999)}",
      'active': true,
      'data_type': 'boolean',
      'data_option': {
        'options': {
          'true': '',
          'false': '',
        },
        'default': 'true',
        'screens': {
          'create_middle': {
            'ticket.customer': {
              'shown': true,
              'item_class': 'column'
            },
            'ticket.agent': {
              'shown': true,
              'item_class': 'column'
            }
          },
          'edit': {
            'ticket.customer': {
              'shown': true
            },
            'ticket.agent': {
              'shown': true
            }
          }
        }
      },
      'id': 'c-201'
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)

    migration = ObjectManager::Attribute.migration_execute
    assert_equal(migration, true)

    assert_response(201) # created
    result = JSON.parse(@response.body)

    assert(result)
    assert(result['data_option']['default'])
    assert_equal(result['data_option']['default'], true)
    assert_equal(result['data_type'], 'boolean')
  end

  test '02 converts string to boolean for default value for boolean data type with false' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin@example.com', 'adminpw')

    params = {
      'name': "customerdescription_#{rand(999_999_999)}",
      'object': 'Ticket',
      'display': "custom description #{rand(999_999_999)}",
      'active': true,
      'data_type': 'boolean',
      'data_option': {
        'options': {
          'true': '',
          'false': '',
        },
        'default': 'false',
        'screens': {
          'create_middle': {
            'ticket.customer': {
              'shown': true,
              'item_class': 'column'
            },
            'ticket.agent': {
              'shown': true,
              'item_class': 'column'
            }
          },
          'edit': {
            'ticket.customer': {
              'shown': true
            },
            'ticket.agent': {
              'shown': true
            }
          }
        }
      },
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)

    migration = ObjectManager::Attribute.migration_execute
    assert_equal(migration, true)

    assert_response(201) # created
    result = JSON.parse(@response.body)

    assert(result)
    assert_not(result['data_option']['default'])
    assert_equal(result['data_option']['default'], false)
    assert_equal(result['data_type'], 'boolean')
  end

  test '03 ticket attributes cannot be removed when it is referenced by an overview' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin@example.com', 'adminpw')

    # 1. create a new ticket attribute and execute migration
    migration = ObjectManager::Attribute.migration_execute

    params = {
      'name': 'test_attribute_referenced_by_an_overview',
      'object': 'Ticket',
      'display': 'Test Attribute',
      'active': true,
      'data_type': 'input',
      'data_option': {
        'default': '',
        'type': 'text',
        'maxlength': 120,
        'null': true,
        'options': {},
        'relation': ''
      },
      'screens': {
        'create_middle': {
          'ticket.customer': {
            'shown': true,
            'item_class': 'column'
          },
          'ticket.agent': {
            'shown': true,
            'item_class': 'column'
          }
        },
        'edit': {
          'ticket.customer': {
            'shown': true
          },
          'ticket.agent': {
            'shown': true
          }
        }
      },
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)

    migration = ObjectManager::Attribute.migration_execute
    assert_equal(migration, true)

    # 2. create an overview that uses the attribute
    params = {
      name: 'test_overview',
      roles: Role.where(name: 'Agent').pluck(:name),
      condition: {
        'ticket.state_id': {
          'operator': 'is',
          'value': Ticket::State.all.pluck(:id),
        },
        'ticket.test_attribute_referenced_by_an_overview': {
          'operator': 'contains',
          'value': 'DUMMY'
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
      user_ids: [ '1' ],
    }

    if Overview.where('name like ?', '%test%').empty?
      post '/api/v1/overviews', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
      assert_response(201)
      result = JSON.parse(@response.body)
      assert_equal(Hash, result.class)
      assert_equal('test_overview', result['name'])
    end

    # 3. attempt to delete the ticket attribute
    get '/api/v1/object_manager_attributes', headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    target_attribute = result.select { |x| x['name'] == 'test_attribute_referenced_by_an_overview' && x['object'] == 'Ticket' }
    assert_equal target_attribute.size, 1
    target_id = target_attribute[0]['id']

    delete "/api/v1/object_manager_attributes/#{target_id}", headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    assert @response.body.include?('Overview')
    assert @response.body.include?('test_overview')
    assert @response.body.include?('cannot be deleted!')
  end

  test '04 ticket attributes cannot be removed when it is referenced by a trigger' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin@example.com', 'adminpw')

    # 1. create a new ticket attribute and execute migration
    migration = ObjectManager::Attribute.migration_execute

    params = {
      'name': 'test_attribute_referenced_by_a_trigger',
      'object': 'Ticket',
      'display': 'Test Attribute',
      'active': true,
      'data_type': 'input',
      'data_option': {
        'default': '',
        'type': 'text',
        'maxlength': 120,
        'null': true,
        'options': {},
        'relation': ''
      },
      'screens': {
        'create_middle': {
          'ticket.customer': {
            'shown': true,
            'item_class': 'column'
          },
          'ticket.agent': {
            'shown': true,
            'item_class': 'column'
          }
        },
        'edit': {
          'ticket.customer': {
            'shown': true
          },
          'ticket.agent': {
            'shown': true
          }
        }
      },
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)

    migration = ObjectManager::Attribute.migration_execute
    assert_equal(migration, true)

    # 2. create an trigger that uses the attribute
    params = {
      name: 'test_trigger',
      condition: {
        'ticket.test_attribute_referenced_by_a_trigger': {
          'operator': 'contains',
          'value': 'DUMMY'
        }
      },
      'perform': {
        'ticket.state_id': {
          'value': '2'
        }
      },
      'active': true,
      'id': 'c-3'
    }

    if Trigger.where('name like ?', '%test%').empty?
      post '/api/v1/triggers', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
      assert_response(201)
      result = JSON.parse(@response.body)
      assert_equal(Hash, result.class)
      assert_equal('test_trigger', result['name'])
    end

    # 3. attempt to delete the ticket attribute
    get '/api/v1/object_manager_attributes', headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    target_attribute = result.select { |x| x['name'] == 'test_attribute_referenced_by_a_trigger' && x['object'] == 'Ticket' }
    assert_equal target_attribute.size, 1
    target_id = target_attribute[0]['id']

    delete "/api/v1/object_manager_attributes/#{target_id}", headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    assert @response.body.include?('Trigger')
    assert @response.body.include?('test_trigger')
    assert @response.body.include?('cannot be deleted!')
  end

  test '05 ticket attributes cannot be removed when it is referenced by a scheduler' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin@example.com', 'adminpw')

    # 1. create a new ticket attribute and execute migration
    migration = ObjectManager::Attribute.migration_execute

    params = {
      'name': 'test_attribute_referenced_by_a_scheduler',
      'object': 'Ticket',
      'display': 'Test Attribute',
      'active': true,
      'data_type': 'input',
      'data_option': {
        'default': '',
        'type': 'text',
        'maxlength': 120,
        'null': true,
        'options': {},
        'relation': ''
      },
      'screens': {
        'create_middle': {
          'ticket.customer': {
            'shown': true,
            'item_class': 'column'
          },
          'ticket.agent': {
            'shown': true,
            'item_class': 'column'
          }
        },
        'edit': {
          'ticket.customer': {
            'shown': true
          },
          'ticket.agent': {
            'shown': true
          }
        }
      },
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)

    migration = ObjectManager::Attribute.migration_execute
    assert_equal(migration, true)

    # 2. create a scheduler that uses the attribute
    params = {
      name: 'test_scheduler',
      'timeplan': {
        'days': {
          'Mon': true,
          'Tue': false,
          'Wed': false,
          'Thu': false,
          'Fri': false,
          'Sat': false,
          'Sun': false
        },
        'hours': {
          '0': true,
          '1': false,
          '2': false,
          '3': false,
          '4': false,
          '5': false,
          '6': false,
          '7': false,
          '8': false,
          '9': false,
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
          '0': true,
          '10': false,
          '20': false,
          '30': false,
          '40': false,
          '50': false
        }
      },
      'condition': {
        'ticket.test_attribute_referenced_by_a_scheduler': {
          'operator': 'contains',
          'value': 'DUMMY'
        }
      },
      'perform': {
        'ticket.state_id': {
          'value': '2'
        }
      },
      'disable_notification': true,
      'note': '',
      'active': true,
      'id': 'c-0'
    }

    if Job.where('name like ?', '%test%').empty?
      post '/api/v1/jobs', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
      assert_response(201)
      result = JSON.parse(@response.body)
      assert_equal(Hash, result.class)
      assert_equal('test_scheduler', result['name'])
    end

    # 3. attempt to delete the ticket attribute
    get '/api/v1/object_manager_attributes', headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    target_attribute = result.select { |x| x['name'] == 'test_attribute_referenced_by_a_scheduler' && x['object'] == 'Ticket' }
    assert_equal target_attribute.size, 1
    target_id = target_attribute[0]['id']

    delete "/api/v1/object_manager_attributes/#{target_id}", headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    assert @response.body.include?('Job')
    assert @response.body.include?('test_scheduler')
    assert @response.body.include?('cannot be deleted!')
  end

  test '06 ticket attributes can be removed when it is referenced by an overview but by user object' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin@example.com', 'adminpw')

    # 1. create a new ticket attribute and execute migration
    migration = ObjectManager::Attribute.migration_execute

    params = {
      'name': 'test_attribute_referenced_by_an_overview',
      'object': 'Ticket',
      'display': 'Test Attribute',
      'active': true,
      'data_type': 'input',
      'data_option': {
        'default': '',
        'type': 'text',
        'maxlength': 120,
        'null': true,
        'options': {},
        'relation': ''
      },
      'screens': {
        'create_middle': {
          'ticket.customer': {
            'shown': true,
            'item_class': 'column'
          },
          'ticket.agent': {
            'shown': true,
            'item_class': 'column'
          }
        },
        'edit': {
          'ticket.customer': {
            'shown': true
          },
          'ticket.agent': {
            'shown': true
          }
        }
      },
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)

    params = {
      'name': 'test_attribute_referenced_by_an_overview',
      'object': 'User',
      'display': 'Test Attribute',
      'active': true,
      'data_type': 'input',
      'data_option': {
        'default': '',
        'type': 'text',
        'maxlength': 120,
        'null': true,
        'options': {},
        'relation': ''
      },
      'screens': {
        'create_middle': {
          'ticket.customer': {
            'shown': true,
            'item_class': 'column'
          },
          'ticket.agent': {
            'shown': true,
            'item_class': 'column'
          }
        },
        'edit': {
          'ticket.customer': {
            'shown': true
          },
          'ticket.agent': {
            'shown': true
          }
        }
      },
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)

    migration = ObjectManager::Attribute.migration_execute
    assert_equal(migration, true)

    # 2. create an overview that uses the attribute
    params = {
      name: 'test_overview',
      roles: Role.where(name: 'Agent').pluck(:name),
      condition: {
        'ticket.state_id': {
          'operator': 'is',
          'value': Ticket::State.all.pluck(:id),
        },
        'ticket.test_attribute_referenced_by_an_overview': {
          'operator': 'contains',
          'value': 'DUMMY'
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
      user_ids: [ '1' ],
    }

    if Overview.where('name like ?', '%test%').empty?
      post '/api/v1/overviews', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
      assert_response(201)
      result = JSON.parse(@response.body)
      assert_equal(Hash, result.class)
      assert_equal('test_overview', result['name'])
    end

    # 3. attempt to delete the ticket attribute
    get '/api/v1/object_manager_attributes', headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    target_attribute = result.select { |x| x['name'] == 'test_attribute_referenced_by_an_overview' && x['object'] == 'User' }
    assert_equal target_attribute.size, 1
    target_id = target_attribute[0]['id']

    delete "/api/v1/object_manager_attributes/#{target_id}", headers: @headers.merge('Authorization' => credentials)
    assert_response(200)

    target_attribute = result.select { |x| x['name'] == 'test_attribute_referenced_by_an_overview' && x['object'] == 'Ticket' }
    assert_equal target_attribute.size, 1
    target_id = target_attribute[0]['id']

    delete "/api/v1/object_manager_attributes/#{target_id}", headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    assert @response.body.include?('Overview')
    assert @response.body.include?('test_overview')
    assert @response.body.include?('cannot be deleted!')
  end

  test '07 verify if attribute type can not be changed' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin@example.com', 'adminpw')

    params = {
      'name': "customerdescription_#{rand(999_999_999)}",
      'object': 'Ticket',
      'display': "custom description #{rand(999_999_999)}",
      'active': true,
      'data_type': 'boolean',
      'data_option': {
        'options': {
          'true': '',
          'false': '',
        },
        'default': 'false',
        'screens': {
          'create_middle': {
            'ticket.customer': {
              'shown': true,
              'item_class': 'column'
            },
            'ticket.agent': {
              'shown': true,
              'item_class': 'column'
            }
          },
          'edit': {
            'ticket.customer': {
              'shown': true
            },
            'ticket.agent': {
              'shown': true
            }
          }
        }
      },
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)

    assert_response(201) # created
    result = JSON.parse(@response.body)

    assert(result)
    assert_not(result['data_option']['default'])
    assert_equal(result['data_option']['default'], false)
    assert_equal(result['data_type'], 'boolean')

    migration = ObjectManager::Attribute.migration_execute
    assert_equal(migration, true)

    params['data_type'] = 'input'
    params['data_option'] = {
      'default': 'test',
      'type': 'text',
      'maxlength': 120
    }

    put "/api/v1/object_manager_attributes/#{result['id']}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result)
    assert(result['error']['Can\'t be changed data_type of attribute. Drop the attribute and recreate it with new data_type.'])

  end

  test '08 verify if attribute type can be changed' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin@example.com', 'adminpw')

    params = {
      'name': "customerdescription_#{rand(999_999_999)}",
      'object': 'Ticket',
      'display': "custom description #{rand(999_999_999)}",
      'active': true,
      'data_type': 'input',
      'data_option': {
        'default': 'test',
        'type': 'text',
        'maxlength': 120,
      },
      'screens': {
        'create_middle': {
          'ticket.customer': {
            'shown': true,
            'item_class': 'column'
          },
          'ticket.agent': {
            'shown': true,
            'item_class': 'column'
          }
        },
        'edit': {
          'ticket.customer': {
            'shown': true
          },
          'ticket.agent': {
            'shown': true
          }
        },
      },
    }

    post '/api/v1/object_manager_attributes', params: params.to_json, headers: @headers.merge('Authorization' => credentials)

    assert_response(201) # created
    result = JSON.parse(@response.body)

    assert(result)
    assert_equal(result['data_option']['default'], 'test')
    assert_equal(result['data_type'], 'input')

    migration = ObjectManager::Attribute.migration_execute
    assert_equal(migration, true)

    params['data_type'] = 'select'
    params['data_option'] = {
      'default': 'fuu',
      'options': {
        'key1': 'foo',
        'key2': 'fuu',
      }
    }

    put "/api/v1/object_manager_attributes/#{result['id']}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)

    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result['data_option']['default'], 'test')
    assert_equal(result['data_option_new']['default'], 'fuu')
    assert_equal(result['data_type'], 'select')

  end

end
