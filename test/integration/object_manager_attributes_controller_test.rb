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

  test 'when a select attribute option is deleted old values are replaced with nil when no default exists' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')

    # clean up tickets from previous runs
    ObjectManager::Attribute.all.select { |o| o.name.include? 'test' }.each(&:delete)
    Ticket.pluck(:id).each do |id|
      delete "/api/v1/tickets/#{id}", headers: @headers.merge('Authorization' => credentials)
    end

    test_select_attribute_params = {
      object: 'Ticket',
      data_type: 'select',
      name: 'test_select_attribute',
      display: 'Test Select Attribute',
      active: true,
      data_option: {
        options: {
          to_be_deleted: 'To be deleted',
          to_be_kept: 'To be kept',
          to_be_kept2: 'To be kept 2',
        },
        null: true,
        default: '',
      },
      id: 'c-204',
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
    }
    post '/api/v1/object_manager_attributes', params: test_select_attribute_params.to_json, headers: @headers.merge('Authorization' => credentials)
    result = JSON.parse(@response.body)
    test_select_attribute_id = result['id']

    migration = ObjectManager::Attribute.migration_execute
    assert migration

    # create two tickets, with the test attribute set to to_be_deleted, to_be_kept respectively
    ticket_with_keep_option = {
      'title': 'Test ticket with to_be_kept',
      'group': 'Users',
      'article': {
        'subject': 'some subject',
        'body': 'some message',
        'type': 'note',
        'internal': false
      },
      'customer': 'nicole.braun@zammad.org',
      'note': 'some note',
      'test_select_attribute': 'to_be_kept',
    }

    post '/api/v1/tickets', params: ticket_with_keep_option.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert result
    assert_equal result['test_select_attribute'], 'to_be_kept'
    ticket_with_keep_option_id = result['id']

    # verify that ticket_with_keep_option_id's test attribute is to_be_kept
    get "/api/v1/tickets/#{ticket_with_keep_option_id}", headers: @headers.merge('Authorization' => credentials)
    result = JSON.parse(@response.body)
    assert_equal 'to_be_kept', result['test_select_attribute']

    ticket_with_delete_option = {
      'title': 'Test ticket with to_be_deleted',
      'group': 'Users',
      'article': {
        'subject': 'some subject',
        'body': 'some message',
        'type': 'note',
        'internal': false
      },
      'customer': 'nicole.braun@zammad.org',
      'note': 'some note',
      'test_select_attribute': 'to_be_deleted',
    }

    post '/api/v1/tickets', params: ticket_with_delete_option.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert result
    assert_equal 'to_be_deleted', result['test_select_attribute']
    ticket_with_delete_option_id = result['id']

    # now delete the to_be_deleted option and migrate the database
    test_select_attribute_params[:data_option][:options].delete(:to_be_deleted)
    put "/api/v1/object_manager_attributes/#{test_select_attribute_id}", params: test_select_attribute_params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert result['data_option']['nulloption']
    assert_equal 3, result['data_option']['options'].size
    assert_equal 2, result['data_option_new']['options'].size

    migration = ObjectManager::Attribute.migration_execute
    assert migration

    # verify that ticket_with_delete_option_id's test attribute has been set to nil
    get "/api/v1/tickets/#{ticket_with_delete_option_id}", headers: @headers.merge('Authorization' => credentials)
    result = JSON.parse(@response.body)
    assert_nil result['test_select_attribute']

    # verify that ticket_with_keep_option_id's test attribute is still to_be_kept
    get "/api/v1/tickets/#{ticket_with_keep_option_id}", headers: @headers.merge('Authorization' => credentials)
    result = JSON.parse(@response.body)
    assert_equal 'to_be_kept', result['test_select_attribute']
  end

  test 'when a select attribute option is deleted old values are replaced with the default value' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')

    # clean up tickets from previous runs
    ObjectManager::Attribute.all.select { |o| o.name.include? 'test' }.each(&:delete)
    Ticket.pluck(:id).each do |id|
      delete "/api/v1/tickets/#{id}", headers: @headers.merge('Authorization' => credentials)
    end

    test_select_attribute_params = {
      object: 'Ticket',
      data_type: 'select',
      name: 'test_select_attribute',
      display: 'Test Select Attribute',
      active: true,
      data_option: {
        options: {
          to_be_deleted: 'To be deleted',
          to_be_kept: 'To be kept',
          to_be_kept2: 'To be kept 2',
        },
        null: true,
        default: 'to_be_kept',
      },
      id: 'c-204',
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
    }
    post '/api/v1/object_manager_attributes', params: test_select_attribute_params.to_json, headers: @headers.merge('Authorization' => credentials)
    result = JSON.parse(@response.body)
    test_select_attribute_id = result['id']

    migration = ObjectManager::Attribute.migration_execute
    assert migration

    # create two tickets, with the test attribute set to to_be_deleted, to_be_kept respectively
    ticket_with_keep_option = {
      'title': 'Test ticket with to_be_kept',
      'group': 'Users',
      'article': {
        'subject': 'some subject',
        'body': 'some message',
        'type': 'note',
        'internal': false
      },
      'customer': 'nicole.braun@zammad.org',
      'note': 'some note',
      'test_select_attribute': 'to_be_kept',
    }

    post '/api/v1/tickets', params: ticket_with_keep_option.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert result
    assert_equal result['test_select_attribute'], 'to_be_kept'
    ticket_with_keep_option_id = result['id']

    ticket_with_delete_option = {
      'title': 'Test ticket with to_be_deleted',
      'group': 'Users',
      'article': {
        'subject': 'some subject',
        'body': 'some message',
        'type': 'note',
        'internal': false
      },
      'customer': 'nicole.braun@zammad.org',
      'note': 'some note',
      'test_select_attribute': 'to_be_deleted',
    }

    post '/api/v1/tickets', params: ticket_with_delete_option.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert result
    assert_equal 'to_be_deleted', result['test_select_attribute']
    ticket_with_delete_option_id = result['id']

    # now delete the to_be_deleted option and migrate the database
    test_select_attribute_params[:data_option][:options].delete(:to_be_deleted)
    put "/api/v1/object_manager_attributes/#{test_select_attribute_id}", params: test_select_attribute_params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal 3, result['data_option']['options'].size
    assert_equal 2, result['data_option_new']['options'].size

    migration = ObjectManager::Attribute.migration_execute
    assert migration

    # verify that ticket_with_keep_option_id's test attribute is still to_be_kept
    get "/api/v1/tickets/#{ticket_with_keep_option_id}", headers: @headers.merge('Authorization' => credentials)
    result = JSON.parse(@response.body)
    assert_equal 'to_be_kept', result['test_select_attribute']

    # verify that ticket_with_delete_option_id's test attribute has been set to nil
    get "/api/v1/tickets/#{ticket_with_delete_option_id}", headers: @headers.merge('Authorization' => credentials)
    result = JSON.parse(@response.body)
    assert_equal 'to_be_kept', result['test_select_attribute']
  end
end
