# encoding: utf-8
require 'test_helper'
require 'faraday'

class RestTest < ActiveSupport::TestCase

  test 'users and orgs' do

    if !ENV['BROWSER_URL']
      puts "NOTICE: Do not execute rest tests, no BROWSER_URL=http://some_host:port is defined! e. g. export BROWSER_URL=http://localhost:3000"
      return
    end

    # create agent
    roles  = Role.where( :name => ['Admin', 'Agent'] )
    groups = Group.all

    UserInfo.current_user_id = 1
    admin = User.create_or_update(
      :login         => 'rest-admin',
      :firstname     => 'Rest',
      :lastname      => 'Agent',
      :email         => 'rest-admin@example.com',
      :password      => 'adminpw',
      :active        => true,
      :roles         => roles,
      :groups        => groups,
    )

    # create agent
    roles = Role.where( :name => 'Agent' )
    agent = User.create_or_update(
      :login         => 'rest-agent@example.com',
      :firstname     => 'Rest',
      :lastname      => 'Agent',
      :email         => 'rest-agent@example.com',
      :password      => 'agentpw',
      :active        => true,
      :roles         => roles,
      :groups        => groups,
    )

    # create customer without org
    roles = Role.where( :name => 'Customer' )
    customer_without_org = User.create_or_update(
      :login         => 'rest-customer1@example.com',
      :firstname     => 'Rest',
      :lastname      => 'Customer1',
      :email         => 'rest-customer1@example.com',
      :password      => 'customer1pw',
      :active        => true,
      :roles         => roles,
    )

    # create orgs
    organization = Organization.create_or_update(
      :name => 'Rest Org',
    )
    organization2 = Organization.create_or_update(
      :name => 'Rest Org #2',
    )
    organization3 = Organization.create_or_update(
      :name => 'Rest Org #3',
    )

    # create customer with org
    customer_with_org = User.create_or_update(
      :login           => 'rest-customer2@example.com',
      :firstname       => 'Rest',
      :lastname        => 'Customer2',
      :email           => 'rest-customer2@example.com',
      :password        => 'customer2pw',
      :active          => true,
      :roles           => roles,
      :organization_id => organization.id,
    )

    # not existing user
    request = get( 'not_existing@example.com', 'adminpw', '/api/users')
    assert_equal( request[:response].status, 401 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['error'], 'authentication failed' )

    # username auth, wrong pw
    request = get( 'rest-admin', 'not_existing', '/api/users' )
    assert_equal( request[:response].status, 401 )
    assert_equal( request[:data]['error'], 'authentication failed' )

    # email auth, wrong pw
    request = get( 'rest-admin@example.com', 'not_existing', '/api/users' )
    assert_equal( request[:response].status, 401 )
    assert_equal( request[:data]['error'], 'authentication failed' )

    # username auth
    request = get( 'rest-admin', 'adminpw', '/api/users' )
    assert_equal( request[:response].status, 200 )

    # email auth
    request = get( 'rest-admin@example.com', 'adminpw', '/api/users' )
    assert_equal( request[:response].status, 200 )

    # /users

    # index
    request = get( 'rest-agent@example.com', 'agentpw', '/api/users')
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Array)
    assert( request[:data].length >= 3 )

    # show/:id
    request = get( 'rest-agent@example.com', 'agentpw', '/api/users/' + agent.id.to_s )
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['email'], 'rest-agent@example.com')
    request = get( 'rest-agent@example.com', 'agentpw', '/api/users/' + customer_without_org.id.to_s )
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['email'], 'rest-customer1@example.com')

    # index
    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/users')
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Array)
    assert_equal( request[:data].length, 1 )

    # show/:id
    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/users/' + customer_without_org.id.to_s )
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['email'], 'rest-customer1@example.com')
    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/users/' + customer_with_org.id.to_s )
    assert_equal( request[:response].status, 401 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['email'], nil)

    # index
    request = get( 'rest-customer2@example.com', 'customer2pw', '/api/users')
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Array)
    assert_equal( request[:data].length, 1 )

    # show/:id
    request = get( 'rest-customer2@example.com', 'customer2pw', '/api/users/' + customer_with_org.id.to_s )
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['email'], 'rest-customer2@example.com')
    request = get( 'rest-customer2@example.com', 'customer2pw', '/api/users/' + customer_without_org.id.to_s )
    assert_equal( request[:response].status, 401 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['email'], nil)


    # /organizations

    # index
    request = get( 'rest-agent@example.com', 'agentpw', '/api/organizations')
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Array)
    assert( request[:data].length >= 3 )

    # show/:id
    request = get( 'rest-agent@example.com', 'agentpw', '/api/organizations/' + organization.id.to_s )
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['name'], 'Rest Org')
    request = get( 'rest-agent@example.com', 'agentpw', '/api/organizations/' + organization2.id.to_s )
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['name'], 'Rest Org #2')

    # index
    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/organizations')
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Array)
    assert_equal( request[:data].length, 0 )

    # show/:id
    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/organizations/' + organization.id.to_s )
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['name'], nil)
    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/organizations/' + organization2.id.to_s )
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['name'], nil)

    # index
    request = get( 'rest-customer2@example.com', 'customer2pw', '/api/organizations')
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Array)
    assert_equal( request[:data].length, 1 )

    # show/:id
    request = get( 'rest-customer2@example.com', 'customer2pw', '/api/organizations/' + organization.id.to_s )
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['name'], 'Rest Org')
    request = get( 'rest-customer2@example.com', 'customer2pw', '/api/organizations/' + organization2.id.to_s )
    assert_equal( request[:response].status, 401 )
    assert_equal( request[:data].class, Hash)
    assert_equal( request[:data]['name'], nil)


    # packages
    request = get( 'rest-admin@example.com', 'adminpw', '/api/packages' )
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Hash)
    assert( request[:data]['packages'] )

    request = get( 'rest-agent@example.com', 'agentpw', '/api/packages' )
    assert_equal( request[:response].status, 401 )
    assert_equal( request[:data].class, Hash)
    assert( !request[:data]['name'] )

    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/packages' )
    assert_equal( request[:response].status, 401 )
    assert_equal( request[:data].class, Hash)
    assert( !request[:data]['name'] )

    # settings
    request = get( 'rest-admin@example.com', 'adminpw', '/api/settings' )
    assert_equal( request[:response].status, 200 )
    assert_equal( request[:data].class, Array)
    assert( request[:data][0] )

    request = get( 'rest-agent@example.com', 'agentpw', '/api/settings' )
    assert_equal( request[:response].status, 401 )
    assert_equal( request[:data].class, Hash)
    assert( !request[:data]['name'] )

    request = get( 'rest-customer1@example.com', 'customer1pw', '/api/settings' )
    assert_equal( request[:response].status, 401 )
    assert_equal( request[:data].class, Hash)
    assert( !request[:data]['name'] )

  end
  def get(user, pw, url)
    conn = Faraday.new( :url => ENV['BROWSER_URL'] )
    conn.basic_auth( user, pw )
    response = conn.get url
#    puts 'URL: ' + url
#    puts response.body.to_s
    data = JSON.parse( response.body )
    return { :data => data, :response => response }
  end
end

