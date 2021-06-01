# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class ModelTest < ActiveSupport::TestCase

  test 'create_if_not_exists test' do
    group1 = Group.create_if_not_exists(
      name:          'model1-create_if_not_exists',
      active:        true,
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_raises( ActiveRecord::RecordNotUnique ) do
      Group.create_if_not_exists(
        name:          'model1-Create_If_Not_Exists',
        active:        true,
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    group2 = Group.create_if_not_exists(
      name:          'model1-create_if_not_exists',
      active:        true,
      updated_at:    '2015-02-05 16:39:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(group1.id, group2.id)
    assert_equal(group2.updated_at.to_s, '2015-02-05 16:37:00 UTC')
  end

  test 'create_or_update test' do
    group1 = Group.create_or_update(
      name:          'model1-create_or_update',
      active:        true,
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_raises( ActiveRecord::RecordNotUnique ) do
      Group.create_or_update(
        name:          'model1-Create_Or_Update',
        active:        true,
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    group2 = Group.create_or_update(
      name:          'model1-create_or_update',
      active:        true,
      updated_at:    '2015-02-05 16:39:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(group1.id, group2.id)
    assert_equal(group2.updated_at.to_s, '2015-02-05 16:39:00 UTC')
  end

  test 'references test' do

    # create base
    groups = Group.where(name: 'Users')
    roles  = Role.where(name: %w[Agent Admin])
    agent1 = User.create_or_update(
      login:         'model-agent1@example.com',
      firstname:     'Model',
      lastname:      'Agent1',
      email:         'model-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent2 = User.create_or_update(
      login:         'model-agent2@example.com',
      firstname:     'Model',
      lastname:      'Agent2',
      email:         'model-agent2@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_at:    '2015-02-05 17:37:00',
      updated_by_id: agent1.id,
      created_by_id: 1,
    )
    organization1 = Organization.create_if_not_exists(
      name:          'Model Org 1',
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    organization2 = Organization.create_if_not_exists(
      name:          'Model Org 2',
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: agent1.id,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    User.create_or_update(
      login:           'model-customer1@example.com',
      firstname:       'Model',
      lastname:        'Customer1',
      email:           'model-customer1@example.com',
      password:        'customerpw',
      active:          true,
      organization_id: organization1.id,
      roles:           roles,
      updated_at:      '2015-02-05 16:37:00',
      updated_by_id:   1,
      created_by_id:   1,
    )
    User.create_or_update(
      login:           'model-customer2@example.com',
      firstname:       'Model',
      lastname:        'Customer2',
      email:           'model-customer2@example.com',
      password:        'customerpw',
      active:          true,
      organization_id: nil,
      roles:           roles,
      updated_at:      '2015-02-05 16:37:00',
      updated_by_id:   agent1.id,
      created_by_id:   1,
    )
    User.create_or_update(
      login:           'model-customer3@example.com',
      firstname:       'Model',
      lastname:        'Customer3',
      email:           'model-customer3@example.com',
      password:        'customerpw',
      active:          true,
      organization_id: nil,
      roles:           roles,
      updated_at:      '2015-02-05 16:37:00',
      updated_by_id:   agent1.id,
      created_by_id:   agent1.id,
    )

    # user

    # verify agent1
    references1 = Models.references('User', agent1.id)

    assert_equal(references1['User']['updated_by_id'], 3)
    assert_equal(references1['User']['created_by_id'], 1)
    assert_equal(references1['Organization']['updated_by_id'], 1)
    assert_equal(references1['UserGroup']['user_id'], 1)
    assert_not(references1['Group'])

    references_total1 = Models.references_total('User', agent1.id)
    assert_equal(references_total1, 8)

    # verify agent2
    references2 = Models.references('User', agent2.id)

    assert_not(references2['User'])
    assert_not(references2['Organization'])
    assert_not(references2['Group'])
    assert_equal(references2['UserGroup']['user_id'], 1)

    references_total2 = Models.references_total('User', agent2.id)
    assert_equal(references_total2, 1)

    Models.merge('User', agent2.id, agent1.id)

    # verify agent1
    references1 = Models.references('User', agent1.id)

    assert_not(references1['User'])
    assert_not(references1['Organization'])
    assert_not(references1['Group'])
    assert_not(references1['UserGroup'])
    assert(references1.blank?)

    references_total1 = Models.references_total('User', agent1.id)
    assert_equal(references_total1, 0)

    # verify agent2
    references2 = Models.references('User', agent2.id)

    assert_equal(references2['User']['updated_by_id'], 3)
    assert_equal(references2['User']['created_by_id'], 1)
    assert_equal(references2['Organization']['updated_by_id'], 1)
    assert_equal(references2['UserGroup']['user_id'], 2)
    assert_not(references2['Group'])

    references_total2 = Models.references_total('User', agent2.id)
    assert_equal(references_total2, 9)

    # org

    # verify agent1
    references1 = Models.references('Organization', organization1.id)

    assert_equal(references1['User']['organization_id'], 1)
    assert_not(references1['Organization'])
    assert_not(references1['Group'])

    references_total1 = Models.references_total('Organization', organization1.id)
    assert_equal(references_total1, 1)

    # verify agent2
    references2 = Models.references('Organization', organization2.id)

    assert(references2.blank?)

    references_total2 = Models.references_total('Organization', organization2.id)
    assert_equal(references_total2, 0)

    Models.merge('Organization', organization2.id, organization1.id)

    # verify agent1
    references1 = Models.references('Organization', organization1.id)

    assert(references1.blank?)

    references_total1 = Models.references_total('Organization', organization1.id)
    assert_equal(references_total1, 0)

    # verify agent2
    references2 = Models.references('Organization', organization2.id)

    assert_equal(references2['User']['organization_id'], 1)
    assert_not(references2['Organization'])
    assert_not(references2['Group'])

    references_total2 = Models.references_total('Organization', organization2.id)
    assert_equal(references_total2, 1)

  end

  test 'searchable test' do
    searchable = Models.searchable
    assert(searchable.include?(Ticket))
    assert(searchable.include?(User))
    assert(searchable.include?(Organization))
    assert(searchable.include?(Chat::Session))
    assert(searchable.include?(KnowledgeBase::Answer::Translation))
    assert_equal(5, searchable.count)
  end

  test 'param_cleanup test' do
    params = {
      id:            123,
      abc:           true,
      firstname:     '123',
      created_by_id: 1,
      created_at:    Time.zone.now,
      updated_by_id: 1,
      updated_at:    Time.zone.now,
      action:        'some action',
      controller:    'some controller',
    }
    result = User.param_cleanup(params, true)
    assert_not(result.key?(:id))
    assert_not(result.key?(:abc))
    assert_equal('123', result[:firstname])
    assert_not(result.key?(:created_by_id))
    assert_not(result.key?(:created_at))
    assert_not(result.key?(:updated_by_id))
    assert_not(result.key?(:updated_at))
    assert_not(result.key?(:action))
    assert_not(result.key?(:controller))

    params = {
      id:            123,
      abc:           true,
      firstname:     '123',
      created_by_id: 1,
      created_at:    Time.zone.now,
      updated_by_id: 1,
      updated_at:    Time.zone.now,
      action:        'some action',
      controller:    'some controller',
    }
    result = User.param_cleanup(params)
    assert_equal(123, result[:id])
    assert_not(result.key?(:abc))
    assert_equal('123', result[:firstname])
    assert_not(result.key?(:created_by_id))
    assert_not(result.key?(:created_at))
    assert_not(result.key?(:updated_by_id))
    assert_not(result.key?(:updated_at))
    assert_not(result.key?(:action))
    assert_not(result.key?(:controller))

    Setting.set('import_mode', true)

    params = {
      id:            123,
      abc:           true,
      firstname:     '123',
      created_by_id: 1,
      created_at:    Time.zone.now,
      updated_by_id: 1,
      updated_at:    Time.zone.now,
      action:        'some action',
      controller:    'some controller',
    }
    result = User.param_cleanup(params, true)
    assert_not(result.key?(:abc))
    assert_equal('123', result[:firstname])
    assert_equal(1, result[:created_by_id])
    assert(result[:created_at])
    assert_equal(1, result[:updated_by_id])
    assert(result[:updated_at])
    assert_not(result.key?(:action))
    assert_not(result.key?(:controller))

    params = {
      id:            123,
      abc:           true,
      firstname:     '123',
      created_by_id: 1,
      created_at:    Time.zone.now,
      updated_by_id: 1,
      updated_at:    Time.zone.now,
      action:        'some action',
      controller:    'some controller',
    }
    result = User.param_cleanup(params)
    assert_equal(123, result[:id])
    assert_equal('123', result[:firstname])
    assert_equal(1, result[:created_by_id])
    assert(result[:created_at])
    assert_equal(1, result[:updated_by_id])
    assert(result[:updated_at])
    assert_not(result.key?(:action))
    assert_not(result.key?(:controller))
  end

  test 'param_preferences_merge test' do
    params = {
      id:            123,
      firstname:     '123',
      created_by_id: 1,
      created_at:    Time.zone.now,
      updated_by_id: 1,
      updated_at:    Time.zone.now,
      preferences:   {},
    }
    user = User.new(params)
    assert(user.preferences.blank?)

    user.preferences = { A: 1, B: 2 }
    assert(user.preferences.present?)

    params = {
      firstname:   '123 ABC',
      preferences: { 'B' => 3, C: 4 },
    }
    clean_params = User.param_cleanup(params)
    clean_user_params = user.param_preferences_merge(clean_params)
    assert_equal(clean_user_params[:firstname], '123 ABC')
    assert(clean_user_params[:preferences].present?)
    assert_equal(clean_user_params[:preferences]['A'], 1)
    assert_equal(clean_user_params[:preferences]['B'], 3)
    assert_equal(clean_user_params[:preferences]['C'], 4)
    assert_equal(clean_user_params[:preferences][:A], 1)
    assert_equal(clean_user_params[:preferences][:B], 3)
    assert_equal(clean_user_params[:preferences][:C], 4)

    params = {
      firstname:   '123 ABCD',
      preferences: {},
    }
    clean_params = User.param_cleanup(params)
    clean_user_params = user.param_preferences_merge(clean_params)
    assert_equal(clean_user_params[:firstname], '123 ABCD')
    assert(clean_user_params[:preferences].present?)
    assert_equal(clean_user_params[:preferences]['A'], 1)
    assert_equal(clean_user_params[:preferences]['B'], 2)
    assert_nil(clean_user_params[:preferences]['C'])
    assert_equal(clean_user_params[:preferences][:A], 1)
    assert_equal(clean_user_params[:preferences][:B], 2)
    assert_nil(clean_user_params[:preferences][:C])
  end

end
