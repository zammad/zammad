# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Null
  def fetchable?(_channel)
    false
  end

  def fetch(*)
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
