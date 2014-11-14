ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'cache'

class ActiveSupport::TestCase
  # disable transactions
  #self.use_transactional_fixtures = false

  # clear cache
  Cache.clear

  # load seeds
  load "#{Rails.root}/db/seeds.rb"

  Setting.set("import_otrs_endpoint", "http://vz305.demo.znuny.com/otrs/public.pl?Action=ZammadMigrator")
  Setting.set("import_otrs_endpoint_key", "01234567899876543210")
  Setting.set("import_mode", true)
  Import::OTRS2.start

  setup do

    # set current user
    #puts 'reset UserInfo.current_user_id'
    #UserInfo.current_user_id = nil
  end

  # Add more helper methods to be used by all tests here...
end
