# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Tool::ObjectLink::User < Service::AI::Tool::ObjectLink
  page 'User', 'user/profile/%{id}'

  # A user stands in a result as the customer, the owner, …: the role names them.
  def self.label_of(row, key: nil)
    key && key != 'user' ? "#{key.humanize} (user #{row['id']})" : "User #{row['id']}"
  end
end
