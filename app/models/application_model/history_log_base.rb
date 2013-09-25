# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::HistoryLogBase

=begin

create history entry for this object

  organization = Organization.find(123)
  result = organization.history_create( 'created', user_id )

returns

  result = true # false

=end

  def history_create (type, user_id, data = {})
    data[:o_id]                   = self['id']
    data[:history_type]           = type
    data[:history_object]         = self.class.name
    data[:related_o_id]           = nil
    data[:related_history_object] = nil
    data[:created_by_id]          = user_id
    History.add(data)
  end

=begin

get history log for this object

  organization = Organization.find(123)
  result = organization.history_get()

returns

  result = [
    {
      :history_type      => 'created',
      :history_object    => 'Organization',
      :created_by_id     => 3,
      :created_at        => "2013-08-19 20:41:33",
    },
    {
      :history_type      => 'updated',
      :history_object    => 'Organization',
      :history_attribute => 'note',
      :o_id              => 1,
      :id_to             => nil,
      :id_from           => nil,
      :value_from        => "some note",
      :value_to          => "some other note",
      :created_by_id     => 3,
      :created_at        => "2013-08-19 20:41:33",
    },
  ]

=end

  def history_get
    History.list( self.class.name, self['id'] )
  end

end