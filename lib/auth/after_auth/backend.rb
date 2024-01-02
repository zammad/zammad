# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Auth::AfterAuth::Backend
  def self.run(...)
    new(...).run
  end

  def self.type
    name.demodulize
  end

  attr_accessor :user, :session, :data

  def initialize(user:, session:)
    @user = user
    @session = session
    @data = {}
  end

  def run
    return nil if !check

    {
      type: self.class.type,
      data: data,
    }
  end

  private

  def check
    raise NotImplementedError
  end
end
