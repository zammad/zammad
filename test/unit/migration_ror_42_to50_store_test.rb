
# Rails 5.0 has changed to only store and read ActiveSupport::HashWithIndifferentAccess from stores
# we extended lib/core_ext/active_record/store/indifferent_coder.rb to read also ActionController::Parameters
# and convert them to ActiveSupport::HashWithIndifferentAccess for migration in db/migrate/20170910000001_fixed_store_upgrade_45.rb.

require 'test_helper'

class MigrationRor42To50StoreTest < ActiveSupport::TestCase
  test 'store with ActionController::Parameters object - get ActiveSupport::HashWithIndifferentAccess' do

    user = User.last
    last_contact = '2017-09-01 10:10:00'
    state = "--- !ruby/hash-with-ivars:ActionController::Parameters
elements:
  ticket: !ruby/hash-with-ivars:ActionController::Parameters
    elements: {}
    ivars:
      :@permitted: false
  article: !ruby/hash-with-ivars:ActionController::Parameters
    elements: {}
    ivars:
      :@permitted: false
ivars:
  :@permitted: false
"
    params = "--- !ruby/hash-with-ivars:ActionController::Parameters
elements:
  ticket_id: 1234
  shown: true
ivars:
  :@permitted: false
"
    preferences = "--- !ruby/hash-with-ivars:ActionController::Parameters
elements:
  tasks: &1
  - !ruby/hash-with-ivars:ActionController::Parameters
    elements:
      id: 99282
      user_id: 85370
      last_contact: 2017-09-08 11:28:00.289663000 Z
      changed: true
    ivars:
      :@permitted: false
ivars:
  :@permitted: false
  :@converted_arrays: !ruby/object:Set
    hash:
      *1: true
"
    sql = "INSERT INTO taskbars (`user_id`, `client_id`, `key`, `callback`, `state`, `params`, `prio`, `notify`, `active`, `preferences`, `last_contact`, `updated_at`, `created_at`) VALUES (#{user.id}, '123', 'Ticket-123', 'TicketZoom', '#{state}', '#{params}', 1, FALSE, TRUE, '#{preferences}', '#{last_contact}', '#{last_contact}', '#{last_contact}')"
    if ActiveRecord::Base.connection_config[:adapter] != 'mysql2'
      sql.delete!('`')
    end
    records_array = ActiveRecord::Base.connection.execute(sql)

    taskbar = Taskbar.last
    assert(taskbar)
    assert(taskbar.params)
    assert_equal(ActiveSupport::HashWithIndifferentAccess, taskbar.params.class)
    assert_equal(1234, taskbar.params[:ticket_id])
    assert(taskbar.state)
    assert_equal(ActiveSupport::HashWithIndifferentAccess, taskbar.state.class)
    assert(taskbar.state[:ticket].blank?)
    assert(ActiveSupport::HashWithIndifferentAccess, taskbar.state[:ticket].class)
    assert(taskbar.state[:article].blank?)
    assert(ActiveSupport::HashWithIndifferentAccess, taskbar.state[:article].class)

    taskbar.save!
    taskbar.reload
    assert(taskbar)
    assert(taskbar.params)
    assert_equal(ActiveSupport::HashWithIndifferentAccess, taskbar.params.class)
    assert_equal(1234, taskbar.params[:ticket_id])
    assert(taskbar.state)
    assert_equal(ActiveSupport::HashWithIndifferentAccess, taskbar.state.class)
    assert(taskbar.state[:ticket].blank?)
    assert(ActiveSupport::HashWithIndifferentAccess, taskbar.state[:ticket].class)
    assert(taskbar.state[:article].blank?)
    assert(ActiveSupport::HashWithIndifferentAccess, taskbar.state[:article].class)
  end

end
