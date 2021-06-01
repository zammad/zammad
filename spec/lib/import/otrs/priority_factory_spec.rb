# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/factory_examples'

RSpec.describe Import::OTRS::PriorityFactory do
  it_behaves_like 'Import::Factory'

  it 'imports records' do

    import_data = {
      name: 'test',
    }
    allow(::Import::OTRS::Priority).to receive(:new)
    described_class.import([import_data])

    expect(::Import::OTRS::Priority).to have_received(:new).with(import_data)
  end

  it 'sets default create Priority' do
    priority                = ::Ticket::Priority.first
    priority.default_create = false
    priority.callback_loop  = true
    priority.save

    allow(Import::OTRS::SysConfigFactory).to receive(:postmaster_default_lookup).with(:priority_default_create).and_return(priority.name)

    described_class.update_attribute_settings
    priority.reload

    expect(priority.default_create).to be true
  end

  it "doesn't set default create Priority in diff import" do
    priority                = ::Ticket::Priority.first
    priority.default_create = false
    priority.callback_loop  = true
    priority.save

    allow(Import::OTRS).to receive(:diff?).and_return(true)

    described_class.update_attribute_settings
    priority.reload

    expect(priority.default_create).to be false
  end
end
