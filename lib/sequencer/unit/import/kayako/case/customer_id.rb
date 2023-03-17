# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Case::CustomerId < Sequencer::Unit::Common::Provider::Named

  uses :resource, :id_map

  private

  def customer_id
    id_map['User'].fetch(resource['requester']&.fetch('id'), 1)
  end
end
