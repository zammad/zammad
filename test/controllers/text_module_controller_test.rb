
require 'test_helper'
require 'rake'

class TextModuleControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1

    @admin = User.create!(
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
    roles = Role.where(name: 'Agent')
    @agent = User.create!(
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
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create!(
      login: 'rest-customer1@example.com',
      firstname: 'Rest',
      lastname: 'Customer1',
      email: 'rest-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

    # create customer
    @customer_with_org = User.create!(
      login: 'rest-customer2@example.com',
      firstname: 'Rest',
      lastname: 'Customer2',
      email: 'rest-customer2@example.com',
      password: 'customer2pw',
      active: true,
      roles: roles,
    )

    UserInfo.current_user_id = nil
  end

  test '05.01 csv example - customer no access' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-customer1@example.com', 'customer1pw')

    get '/api/v1/text_modules/import_example', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('Not authorized (user)!', result['error'])
  end

  test '05.02 csv example - admin access' do
    TextModule.load('en-en')

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    get '/api/v1/text_modules/import_example', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    rows = CSV.parse(@response.body)
    header = rows.shift

    assert_equal('id', header[0])
    assert_equal('name', header[1])
    assert_equal('keywords', header[2])
    assert_equal('content', header[3])
    assert_equal('note', header[4])
    assert_equal('active', header[5])
    assert_not(header.include?('organization'))
    assert_not(header.include?('priority'))
    assert_not(header.include?('state'))
    assert_not(header.include?('owner'))
    assert_not(header.include?('customer'))
  end

  test '05.03 csv import - admin access' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    # invalid file
    csv_file_path = Rails.root.join('test', 'data', 'csv', 'text_module_simple_col_not_existing.csv')
    csv_file = ::Rack::Test::UploadedFile.new(csv_file_path, 'text/csv')
    post '/api/v1/text_modules/import?try=true', params: { file: csv_file, col_sep: ';' }, headers: { 'Authorization' => credentials }
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal(true, result['try'])
    assert_equal(2, result['records'].count)
    assert_equal('failed', result['result'])
    assert_equal(2, result['errors'].count)
    assert_equal("Line 1: unknown attribute 'keywords2' for TextModule.", result['errors'][0])
    assert_equal("Line 2: unknown attribute 'keywords2' for TextModule.", result['errors'][1])

    # valid file try
    csv_file_path = Rails.root.join('test', 'data', 'csv', 'text_module_simple.csv')
    csv_file = ::Rack::Test::UploadedFile.new(csv_file_path, 'text/csv')
    post '/api/v1/text_modules/import?try=true', params: { file: csv_file, col_sep: ';' }, headers: { 'Authorization' => credentials }
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal(true, result['try'])
    assert_equal(2, result['records'].count)
    assert_equal('success', result['result'])

    assert_nil(TextModule.find_by(name: 'some name1'))
    assert_nil(TextModule.find_by(name: 'some name2'))

    # valid file
    csv_file_path = Rails.root.join('test', 'data', 'csv', 'text_module_simple.csv')
    csv_file = ::Rack::Test::UploadedFile.new(csv_file_path, 'text/csv')
    post '/api/v1/text_modules/import', params: { file: csv_file, col_sep: ';' }, headers: { 'Authorization' => credentials }
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal(false, result['try'])
    assert_equal(2, result['records'].count)
    assert_equal('success', result['result'])

    text_module1 = TextModule.find_by(name: 'some name1')
    assert(text_module1)
    assert_equal(text_module1.name, 'some name1')
    assert_equal(text_module1.keywords, 'keyword1')
    assert_equal(text_module1.content, 'some<br>content1')
    assert_equal(text_module1.active, true)
    text_module2 = TextModule.find_by(name: 'some name2')
    assert(text_module2)
    assert_equal(text_module2.name, 'some name2')
    assert_equal(text_module2.keywords, 'keyword2')
    assert_equal(text_module2.content, 'some content<br>test123')
    assert_equal(text_module2.active, true)

  end

end
