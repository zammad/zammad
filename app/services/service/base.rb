# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Base
  class_attribute :current_user_required, default: false

  def execute
    raise NotImplementedError
  end

  def current_user
    @current_user ||= UserInfo.current_user
  end

  def self.execute(*, current_user: nil, **, &)
    Rails.logger.debug current_user

    case { current_user:, current_user_required: }
    in { current_user: nil, current_user_required: false }
      new(*, **, &).execute
    in { current_user: nil, current_user_required: true }
      raise "Current user is required for #{name}"
    in { current_user: false, current_user_required: false }
      UserInfo.with_user_id(nil) do
        new(*, **, &).execute
      end
    in { current_user:, current_user_required: _ }
      UserInfo.with_user_id(current_user.id) do
        new(*, **, &).execute
      end
    end
  end

  def self.with_current_user(current_user)
    Proxy.new(self, current_user)
  end

  def self.requires_current_user!
    self.current_user_required = true
  end

  class Proxy
    attr_reader :klass, :current_user

    def initialize(klass, current_user)
      @klass = klass
      @current_user = current_user
    end

    def execute(*, **, &)
      klass.execute(*, current_user:, **, &)
    end
  end
end
