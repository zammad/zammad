require 'test_helper'
require 'rake'

class ObjectManagerAttributesControllerTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

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
      'id': 'c-202'
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

  test 'ticket creation and updates without required attributes will be correctly rejected' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')

    # add a required text attribute
    object = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'required_text',
      display: 'Required Text Display Name',
      data_type: 'input',
      active: true,
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
            required: true,
            item_class: 'column'
          },
          'ticket.agent' => {
            shown: true,
            required: true,
            item_class: 'column'
          }
        },
        edit: {
          'ticket.customer' => {
            shown: true,
            required: true
          },
          'ticket.agent' => {
            shown: true,
            required: true
          }
        }
      },
      position: 1500,
      editable: true
    )

    migration = ObjectManager::Attribute.migration_execute
    assert migration

    ticket_without_required_text = {
      'title': 'Test ticket without required text',
      'group': 'Users',
      'article': {
        'subject': 'some subject',
        'body': 'some message',
        'type': 'note',
        'internal': false
      },
      'customer': 'nicole.braun@zammad.org',
      'note': 'some note',
    }

    # confirm that a ticket without the required text will be correctly rejected with a 422: Unprocessable Entity
    post '/api/v1/tickets', params: ticket_without_required_text.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    assert @response.body.include?('Required Text Display Name')

    ticket_with_required_text = ticket_without_required_text.clone
    ticket_with_required_text['required_text'] = 'Some required text'
    ticket_with_required_text['title'] = 'Test ticket with required text'

    # confirm that a ticket with the required text will be correctly created with a 201: Created
    post '/api/v1/tickets', params: ticket_with_required_text.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert result
    assert_equal result['title'], 'Test ticket with required text'
    assert_equal result['required_text'], 'Some required text'
    ticket_id = result['id']

    # attempt to update the ticket without the required text field
    update_without_required_text = {
      'title': 'Updated ticket without required text',
    }
    put "/api/v1/tickets/#{ticket_id}", params: update_without_required_text.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    assert @response.body.include?('Required Text Display Name')

    # attempt to update the ticket with the required text field
    update_with_required_text = {
      'title': 'Updated ticket required text',
      'required_text': 'Some other required text'
    }
    put "/api/v1/tickets/#{ticket_id}", params: update_with_required_text.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert result
    assert_equal result['title'], 'Updated ticket required text'
    assert_equal result['required_text'], 'Some other required text'
    assert_equal result['id'], ticket_id

    # confirm that datetime attributes with allow_future/allow_past restrictions will correctly reject invalid inputs
    object = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'required_datetime',
      display: 'Required Datetime Display Name',
      data_type: 'datetime',
      active: true,
      data_option: {
        'future' => true,
        'past' => false,
        'diff' => 24,
        'default' => nil,
        'null' => true,
      },
      screens: {
        'create_middle' => {
          'ticket.customer' => {
            'shown' => true,
            'required' => true,
            'item_class' => 'column'
          },
          'ticket.agent' => {
            'shown' => true,
            'required' => true,
            'item_class' => 'column'
          }
        },
        'edit' => {
          'ticket.customer' => {
            'shown' => true,
            'required' => true
          },
          'ticket.agent' => {
            'shown' => true,
            'required' => true
          }
        }
      },
      position: 1550,
      editable: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    migration = ObjectManager::Attribute.migration_execute
    assert migration
    new_datatime = ObjectManager::Attribute.all.select { |a| a.name == 'required_datetime' }
    assert_equal new_datatime.length, 1

    ticket_without_date = {
      'title': 'Test ticket without required date',
      'group': 'Users',
      'article': {
        'subject': 'some subject',
        'body': 'some message',
        'type': 'note',
        'internal': false
      },
      'customer': 'nicole.braun@zammad.org',
      'note': 'some note',
      'required_text': 'Yet some other required text'
    }

    # confirm that a ticket without the required date will be correctly rejected with a 422: Unprocessable Entity
    post '/api/v1/tickets', params: ticket_without_date.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    assert @response.body.include?('Required Datetime Display Name')

    ticket_with_future_date = ticket_without_date.clone
    required_datetime = Time.now.tomorrow.utc
    ticket_with_future_date['required_datetime'] = required_datetime.to_s
    ticket_with_future_date['title'] = 'Test ticket with required date'

    # confirm that a ticket with the required date will be correctly accepted with a 201: Created
    post '/api/v1/tickets', params: ticket_with_future_date.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert result
    assert_equal result['title'], 'Test ticket with required date'
    assert_in_delta Time.zone.parse(result['required_datetime']), required_datetime, 1.second

    # confirm that a ticket with a past date will be correctly rejected with a 422: Unprocessable Entity
    ticket_with_past_date = ticket_with_future_date.clone
    ticket_with_past_date['required_datetime'] = Time.now.yesterday.utc.to_s
    post '/api/v1/tickets', params: ticket_with_past_date.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    assert @response.body.include?('Required Datetime Display Name')
    assert @response.body.include?('does not allow past dates')
  end
end
