require 'rails_helper'
require 'import/transaction_factory_examples'

RSpec.describe Import::OTRS::StateFactory do
  it_behaves_like 'Import::TransactionFactory'

  it 'creates a state backup in the pre_import_hook' do
    expect(described_class).to receive(:backup)
    described_class.pre_import_hook([])
  end

  def load_state_json(file)
    json_fixture("import/otrs/state/#{file}")
  end

  it 'updates ObjectManager Ticket state_id and pending_time filter' do

    states = %w(new open merged pending_reminder pending_auto_close_p pending_auto_close_n pending_auto_close_p closed_successful closed_unsuccessful closed_successful removed)

    state_backend_param = []
    states.each do |state|
      state_backend_param.push(load_state_json(state))
    end

    ticket_state_id = ::ObjectManager::Attribute.get(
      object: 'Ticket',
      name:   'state_id',
    )
    ticket_pending_time = ::ObjectManager::Attribute.get(
      object: 'Ticket',
      name:   'pending_time',
    )

    expect {
      described_class.import(state_backend_param)

      # sync changes
      ticket_state_id.reload
      ticket_pending_time.reload
    }.to change {
      ticket_state_id.data_option
    }.and change {
      ticket_state_id.screens
    }.and change {
      ticket_pending_time.data_option
    }
  end
end
