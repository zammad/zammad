# This module registers a before and after each hook callback that
# resets the stored current_user_id in the UserInfo which will otherwise
# persists across multiple examples.
# This can lead to issues where actions were performed by a user created
# via a FactoryBot factory which will get removed after the example is
# completed. The UserInfo.current_user_id will persist which leads to e.g.
# DB ForeignKey violation errors.
module ZammadSpecSupportUserInfo

  def self.included(base)

    # Execute in RSpec class context
    base.class_exec do

      before(:each) do |_example|
        UserInfo.current_user_id = nil
      end

      after(:each) do |_example|
        UserInfo.current_user_id = nil
      end
    end
  end
end

RSpec.configure do |config|
  config.include ZammadSpecSupportUserInfo

  config.around(:each, :current_user_id) do |example|
    UserInfo.current_user_id = example.metadata[:current_user_id]
    begin
      example.run
    ensure
      UserInfo.current_user_id = nil
    end
  end
end
