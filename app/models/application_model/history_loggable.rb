# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::HistoryLoggable
  extend ActiveSupport::Concern

=begin

create history entry for this object

  organization = Organization.find(123)
  result = organization.history_log('created', user_id)

returns

  result = true # false

=end

  def history_log(type, user_id, attributes = {})

    attributes.merge!(
      o_id:                   self['id'],
      history_type:           type,
      history_object:         self.class.name,
      related_o_id:           nil,
      related_history_object: nil,
      created_by_id:          user_id,
      updated_at:             updated_at,
      created_at:             updated_at,
    ).merge!(history_log_attributes)

    History.add(attributes)
  end

  # callback function to overwrite
  # default history log attributes
  # gets called from history_log
  def history_log_attributes
    {}
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
    history[:list].each { |item|
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
