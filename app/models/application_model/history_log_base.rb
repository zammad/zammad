# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::HistoryLogBase

=begin

create history entry for this object

  organization = Organization.find(123)
  result = organization.history_log('created', user_id)

returns

  result = true # false

=end

  def history_log (type, user_id, data = {})
    data[:o_id]                   = self['id']
    data[:history_type]           = type
    data[:history_object]         = self.class.name
    data[:related_o_id]           = nil
    data[:related_history_object] = nil
    data[:created_by_id]          = user_id
    data[:updated_at]             = updated_at
    data[:created_at]             = updated_at
    History.add(data)
  end

=begin

get history log for this object

  organization = Organization.find(123)
  result = organization.history_get()

returns

  result = [
    {
      :type          => 'created',
      :object        => 'Organization',
      :created_by_id => 3,
      :created_at    => "2013-08-19 20:41:33",
    },
    {
      :type          => 'updated',
      :object        => 'Organization',
      :attribute     => 'note',
      :o_id          => 1,
      :id_to         => nil,
      :id_from       => nil,
      :value_from    => "some note",
      :value_to      => "some other note",
      :created_by_id => 3,
      :created_at    => "2013-08-19 20:41:33",
    },
  ]

to get history log for this object with all assets

  organization = Organization.find(123)
  result = organization.history_get(true)

returns

  result = {
    :history => [
      { ... },
      { ... },
    ],
    :assets => {
      ...
    }
  }

=end

  def history_get(fulldata = false)
    if !fulldata
      return History.list(self.class.name, self['id'])
    end

    # get related objects
    history = History.list(self.class.name, self['id'], nil, true)
    history[:list].each {|item|
      record = Kernel.const_get(item['object']).find(item['o_id'])

      history[:assets] = record.assets(history[:assets])

      if item['related_object']
        record = Kernel.const_get(item['related_object']).find(item['related_o_id'])
        history[:assets] = record.assets(history[:assets])
      end
    }
    {
      history: history[:list],
      assets: history[:assets],
    }
  end
end
