# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# This file registers a before and after each hook callback that
# resets the stored current_user_id in the UserInfo which will otherwise
# persists across multiple examples.
# This can lead to issues where actions were performed by a user created
# via a FactoryBot factory which will get removed after the example is
# completed. The UserInfo.current_user_id will persist which leads to e.g.
# DB ForeignKey violation errors.
# If a `:current_user_id` metadata argument is set the initial value for
# UserInfo.current_user_id will be set to the arguments given value
# if it's a Proc it will get evaluated
RSpec.configure do |config|

  config.before(:each) do |example|
    current_user_id = example.metadata[:current_user_id]
    UserInfo.current_user_id = current_user_id.is_a?(Proc) ? instance_exec(&current_user_id) : current_user_id
  end

  config.after(:each) do |_example|
    UserInfo.current_user_id = nil
  end
end
