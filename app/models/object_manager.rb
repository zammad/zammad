# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ObjectManager

=begin

list all backend managed object

  ObjectManager.list_objects

=end

  def self.list_objects
    %w[Ticket TicketArticle User Organization Group]
  end

=begin

list all frontend managed object

  ObjectManager.list_frontend_objects

=end

  def self.list_frontend_objects
    %w[Ticket User Organization Group]
  end

end
