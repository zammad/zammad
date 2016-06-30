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
    user_id: 123,
  },
=end

    @item = item
    @params = params
  end

  def perform
    Setting.where(area: 'Transaction::Backend::Async').order(:name).each { |setting|
      backend = Kernel.const_get(Setting.get(setting.name))
      Observer::Transaction.execute_singel_backend(backend, @item, @params)
    }
  end

  def self.run(item, params = {})
    generic = new(item, params)
    generic.perform
  end

end
