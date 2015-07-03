# encoding: utf-8
require 'test_helper'

class ModelTest < ActiveSupport::TestCase
  test 'references test' do

      # create base
    groups = Group.where( name: 'Users' )
    roles  = Role.where( name: %w(Agent Admin) )
    agent1 = User.create_or_update(
      login: 'model-agent1@example.com',
      firstname: 'Model',
      lastname: 'Agent1',
      email: 'model-agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    organization1 = Organization.create_if_not_exists(
      name: 'Model Org 1',
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    organization2 = Organization.create_if_not_exists(
      name: 'Model Org 2',
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: agent1.id,
      created_by_id: 1,
    )
    roles     = Role.where( name: 'Customer' )
    customer1 = User.create_or_update(
      login: 'model-customer1@example.com',
      firstname: 'Model',
      lastname: 'Customer1',
      email: 'model-customer1@example.com',
      password: 'customerpw',
      active: true,
      organization_id: organization1.id,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    customer2 = User.create_or_update(
      login: 'model-customer2@example.com',
      firstname: 'Model',
      lastname: 'Customer2',
      email: 'model-customer2@example.com',
      password: 'customerpw',
      active: true,
      organization_id: nil,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: agent1.id,
      created_by_id: 1,
    )
    customer3 = User.create_or_update(
      login: 'model-customer3@example.com',
      firstname: 'Model',
      lastname: 'Customer3',
      email: 'model-customer3@example.com',
      password: 'customerpw',
      active: true,
      organization_id: nil,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
    )

    references = Models.references('User', agent1.id)

    assert_equal(references[:model]['User'], 3)
    assert_equal(references[:model]['Organization'], 1)
    assert_equal(references[:model]['Group'], 0)
    assert_equal(references[:total],  6)
  end

end
