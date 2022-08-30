# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class User::AddInternalService < BaseService
  def execute(args)
    add(args[:user_data])
  end

  private

  def add(user_data)
    check_attributes(user_data)

    set_core_workflow_information(user_data, ::User)

    user = User.new(user_data)
    user.save!

    user
  end

  def check_attributes(user_data)
    execute_service(User::CheckAttributesService, user_data: user_data)
  end
end
