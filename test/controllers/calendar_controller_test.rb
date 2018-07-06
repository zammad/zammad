
require 'test_helper'

class CalendarControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create!(
      login: 'calendar-admin',
      firstname: 'Packages',
      lastname: 'Admin',
      email: 'calendar-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

  end

  test '01 calendar index with nobody' do

    get '/api/v1/calendars', params: {}, headers: @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('authentication failed', result['error'])

    get '/api/v1/calendars_init', params: {}, headers: @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('authentication failed', result['error'])
  end

  test '02 calendar index with admin' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('calendar-admin@example.com', 'adminpw')

    # index
    get '/api/v1/calendars', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)
    assert_equal(1, result.count)

    get '/api/v1/calendars?expand=true', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)
    assert_equal(1, result.count)

    get '/api/v1/calendars?full=true', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
    assert(result['record_ids'])
    assert_equal(1, result['record_ids'].count)
    assert(result['assets'])
    assert(result['assets'].present?)

    # index
    get '/api/v1/calendars_init', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['record_ids'])
    assert(result['ical_feeds'])
    assert_equal('Denmark', result['ical_feeds']['http://www.google.com/calendar/ical/da.danish%23holiday%40group.v.calendar.google.com/public/basic.ics'])
    assert_equal('Austria', result['ical_feeds']['http://www.google.com/calendar/ical/de.austrian%23holiday%40group.v.calendar.google.com/public/basic.ics'])
    assert(result['timezones'])
    assert_equal(2, result['timezones']['Africa/Johannesburg'])
    assert_equal(-8, result['timezones']['America/Sitka'])
    assert(result['assets'])

  end

end
