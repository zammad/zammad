# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Transaction::BackgroundJob
  def initialize(item, params = {})

=begin
  {
    object: 'Ticket',
    type: 'update',
    ticket_id: 123,
    via_web: true,
    changes: {
      'attribute1' => [before,now],
      'attribute2' => [before,now],
    }
  },
=end

    @item = item
    @params = params
  end

  def perform
    Setting.where(area: 'Transaction::Backend').order(:name).each {|setting|
      backend = Setting.get(setting.name)
      integration = Kernel.const_get(backend).new(@item, @params)
      integration.perform
    }
  end

  def self.run(item, params = {})
    generic = new(item, params)
    generic.perform
  end

end
