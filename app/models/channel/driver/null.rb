# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::Null
  def fetchable?(_channel)
    false
  end

  def fetch(...)
    {
      result:  'ok',
      fetched: 0,
      notice:  '',
    }
  end

  def disconnect
    true
  end

  def self.streamable?
    false
  end
end
