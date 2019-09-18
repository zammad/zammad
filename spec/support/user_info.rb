# This file registers a before and after each hook callback that
# resets the stored current_user_id in the UserInfo which will otherwise
# persists across multiple examples.
# This can lead to issues where actions were performed by a user created
# via a FactoryBot factory which will get removed after the example is
# completed. The UserInfo.current_user_id will persist which leads to e.g.
# DB ForeignKey violation errors.
# If a `:current_user_id` metadata argument is set the initial value for
# UserInfo.current_user_id will be set to the arguments given value
RSpec.configure do |config|

  config.before(:each) do |example|
    UserInfo.current_user_id = example.metadata[:current_user_id]
  end

  config.after(:each) do |_example|
    UserInfo.current_user_id = nil
  end
end
