# encoding: utf-8
require 'test_helper'

class ObjectManagerAttributesControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: 'Admin')
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
  test '01 converts string to boolean for default value for boolean data type' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin@example.com', 'adminpw')

    post '/api/v1/object_manager_attributes', params: { 'name' => 'customdescription2', 'object' => 'Ticket', 'display' => 'custom description 2', 'active' => true, 'data_type' => 'boolean', 'data_option' => { 'options' => { 'true' => '', 'false' => '' }, 'default' => 'true' }, 'screens' => { 'create_middle' => { 'ticket.customer' => { 'shown' => true, 'item_class' => 'column' }, 'ticket.agent' => { 'shown' => true, 'item_class' => 'column' } }, 'edit' => { 'ticket.customer' => { 'shown' => true }, 'ticket.agent' => { 'shown' => true } } }, 'id' => 'c-192' }.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response :success
    result = JSON.parse @response.body
    object = ObjectManager::Attribute.find result['id']
    assert_equal true, object.data_option['default']
    assert_equal 'boolean', object.data_type
    object.destroy
  end
end
