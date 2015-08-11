# encoding: utf-8
require 'test_helper'

class RestTest < ActiveSupport::TestCase

  test 'users and orgs' do

    if !ENV['BROWSER_URL']
      puts 'NOTICE: Do not execute rest tests, no BROWSER_URL=http://some_host:port is defined! e. g. export BROWSER_URL=http://localhost:3000'
      return
    end

    # create agent
    roles  = Role.where( name: %w(Admin Agent) )
    groups = Group.all

    UserInfo.current_user_id = 1
    admin = User.create_or_update(
      login: 'rest-admin',
      firstname: 'Rest',
      lastname: 'Agent',
      email: 'rest-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create agent
    roles = Role.where( name: 'Agent' )
    agent = User.create_or_update(
      login: 'rest-agent@example.com',
      firstname: 'Rest',
      lastname: 'Agent',
      email: 'rest-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where( name: 'Customer' )
    customer_without_org = User.create_or_update(
      login: 'rest-customer1@example.com',
      firstname: 'Rest',
      lastname: 'Customer1',
      email: 'rest-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

    # create orgs
    organization = Organization.create_or_update(
      name: 'Rest Org',
    )
    organization2 = Organization.create_or_update(
      name: 'Rest Org #2',
    )
    organization3 = Organization.create_or_update(
      name: 'Rest Org #3',
    )

    # create customer with org
    customer_with_org = User.create_or_update(
      login: 'rest-customer2@example.com',
      firstname: 'Rest',
      lastname: 'Customer2',
      email: 'rest-customer2@example.com',
      password: 'customer2pw',
      active: true,
      roles: roles,
      organization_id: organization.id,
    )

    # not existing user
    request = get( 'not_existing@example.com', 'adminpw', '/api/v1/users')
    assert_equal( request[:response].code, '401' )
    assert_equal( request[:data].class, NilClass)

    # username auth, wrong pw
    request = get( 'rest-admin', 'not_existing', '/api/v1/users' )
    assert_equal( request[:response].code, '401' )
    assert_equal( request[:data].class, NilClass)

    # email auth, wrong pw
    request = get( 'rest-admin@example.com', 'not_existing', '/api/v1/users' )
    assert_equal( request[:response].code, '401' )
    assert_equal( request[:data].class, NilClass)

    # username auth
    request = get( 'rest-admin', 'adminpw', '/api/v1/users' )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Array)

    # email auth
    request = get( 'rest-admin@example.com', 'adminpw', '/api/v1/users' )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Array)

    # /users

    # index
    request = get( 'rest-agent@example.com', 'agentpw', '/api/v1/users')
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Array)
    assert( request[:data].length >= 3 )

    # show/:id
    request = get( 'rest-agent@example.com', 'agentpw', '/api/v1/users/' + agent.id.to_s )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['email'], 'rest-agent@example.com')
    request = get( 'rest-agent@example.com', 'agentpw', '/api/v1/users/' + customer_without_org.id.to_s )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['email'], 'rest-customer1@example.com')

    # index
    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/v1/users')
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Array)
    assert_equal( request[:data].length, 1 )

    # show/:id
    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/v1/users/' + customer_without_org.id.to_s )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['email'], 'rest-customer1@example.com')
    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/v1/users/' + customer_with_org.id.to_s )
    assert_equal( request[:response].code, '401' )
    assert_equal( request[:data].class, NilClass)

    # index
    request = get( 'rest-customer2@example.com', 'customer2pw', '/api/v1/users')
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Array)
    assert_equal( request[:data].length, 1 )

    # show/:id
    request = get( 'rest-customer2@example.com', 'customer2pw', '/api/v1/users/' + customer_with_org.id.to_s )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['email'], 'rest-customer2@example.com')
    request = get( 'rest-customer2@example.com', 'customer2pw', '/api/v1/users/' + customer_without_org.id.to_s )
    assert_equal( request[:response].code, '401' )
    assert_equal( request[:data].class, NilClass)

    # /organizations

    # index
    request = get( 'rest-agent@example.com', 'agentpw', '/api/v1/organizations')
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Array)
    assert( request[:data].length >= 3 )

    # show/:id
    request = get( 'rest-agent@example.com', 'agentpw', '/api/v1/organizations/' + organization.id.to_s )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['name'], 'Rest Org')
    request = get( 'rest-agent@example.com', 'agentpw', '/api/v1/organizations/' + organization2.id.to_s )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['name'], 'Rest Org #2')

    # index
    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/v1/organizations')
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Array)
    assert_equal( request[:data].length, 0 )

    # show/:id
    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/v1/organizations/' + organization.id.to_s )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['name'], nil)
    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/v1/organizations/' + organization2.id.to_s )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['name'], nil)

    # index
    request = get( 'rest-customer2@example.com', 'customer2pw', '/api/v1/organizations')
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Array)
    assert_equal( request[:data].length, 1 )

    # show/:id
    request = get( 'rest-customer2@example.com', 'customer2pw', '/api/v1/organizations/' + organization.id.to_s )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['name'], 'Rest Org')
    request = get( 'rest-customer2@example.com', 'customer2pw', '/api/v1/organizations/' + organization2.id.to_s )
    assert_equal( request[:response].code, '401' )
    assert_equal( request[:data].class, NilClass)

    # packages
    request = get( 'rest-admin@example.com', 'adminpw', '/api/v1/packages' )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Hash)
    assert( request[:data]['packages'] )

    request = get( 'rest-agent@example.com', 'agentpw', '/api/v1/packages' )
    assert_equal( request[:response].code, '401' )
    assert_equal( request[:data].class, NilClass)

    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/v1/packages' )
    assert_equal( request[:response].code, '401' )
    assert_equal( request[:data].class, NilClass)

    # settings
    request = get( 'rest-admin@example.com', 'adminpw', '/api/v1/settings' )
    assert_equal( request[:response].code, '200' )
    assert_equal( request[:data].class, Array)
    assert( request[:data][0] )

    request = get( 'rest-agent@example.com', 'agentpw', '/api/v1/settings' )
    assert_equal( request[:response].code, '401' )
    assert_equal( request[:data].class, NilClass)

    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/v1/settings' )
    assert_equal( request[:response].code, '401' )
    assert_equal( request[:data].class, NilClass)

  end
  def get(user, pw, url)

    response = UserAgent.get(
      "#{ENV['BROWSER_URL']}#{url}",
      {},
      {
        json: true,
        user: user,
        password: pw,
      }
    )
    #puts 'URL: ' + url
    #puts response.code.to_s
    #puts response.body.to_s
    { data: response.data, response: response }
  end
end
