# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ZammadAuthenticatedAsHelper
  # parse authenticated_as params for request and system test helpers
  #
  # @param input [Any] any to parse, see bellow for options
  # @param return_type [Symbol] :credentials or :user
  def authenticated_as_get_user(input, return_type:)
    case input
    when Proc
      parse_meta instance_exec(&input), return_type: return_type
    when Symbol
      parse_meta instance_eval { send(input) }, return_type: return_type
    else
      parse_meta input, return_type: return_type
    end
  end

  private

  def parse_meta(input, return_type:)
    case return_type
    when :credentials
      parse_meta_credentials(input)
    when :user
      parse_meta_user_object(input)
    end
  end

  def parse_meta_user_object(input)
    case input
    when User
      input
    end
  end

  def parse_meta_credentials(input)
    case input
    when Hash
      input.slice(:username, :password)
    when User
      parse_meta_user(input)
    when true
      {
        username: 'master@example.com',
        password: 'test',
      }
    end
  end

  def parse_meta_user(input)
    password = input.password_plain

    if password.blank?
      password = 'automagically set by your friendly capybara helper'
      input.update!(password: password)
    end

    {
      username: input.email,
      password: password,
    }
  end
end

RSpec.configure do |config|
  %i[request system].each do |type|
    config.include ZammadAuthenticatedAsHelper, type: type
  end
end
