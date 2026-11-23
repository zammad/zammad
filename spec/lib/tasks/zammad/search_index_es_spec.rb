# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'zammad:searchindex:reload', searchindex: true do # rubocop:disable RSpec/DescribeClass
  let(:task) { Rake::Task['zammad:searchindex:reload'] }

  before do
    create_list(:ticket, 3)

    stub_const('SearchIndexBackend::Reload::Records::BATCH_SIZE', 2)
    allow(Models).to receive(:indexable).and_return([Ticket, Ticket::Priority])
  end

  it 'reports the progress of the models and when each of them is done' do
    expect { task.execute(Rake::TaskArguments.new([:worker], [])) }
      .to output(%r{Ticket 2/#{Ticket.count}.*  - Ticket::Priority: #{Ticket::Priority.count} done after \d+ seconds\..*  - Ticket: #{Ticket.count} done after \d+ seconds\.}m).to_stdout
  end

  it 'indexes the records of all models', :aggregate_failures do
    expect { task.execute(Rake::TaskArguments.new([:worker], [])) }.to output.to_stdout

    SearchIndexBackend.refresh

    expect(SearchIndexBackend.search('*', 'Ticket', limit: 100).size).to eq(Ticket.count)
    expect(SearchIndexBackend.search('*', 'Ticket::Priority', limit: 100).size).to eq(Ticket::Priority.count)
  end

  it 'passes the number of workers on', :aggregate_failures do
    reload = instance_double(SearchIndexBackend::Reload, perform: nil)

    allow(SearchIndexBackend::Reload).to receive(:new).and_return(reload)

    expect { task.execute(Rake::TaskArguments.new([:worker], ['2'])) }.to output.to_stdout

    expect(SearchIndexBackend::Reload).to have_received(:new).with([Ticket, Ticket::Priority], worker: 2)
    expect(reload).to have_received(:perform)
  end
end
