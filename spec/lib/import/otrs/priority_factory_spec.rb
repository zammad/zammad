require 'rails_helper'
require 'lib/import/factory_examples'

RSpec.describe Import::OTRS::PriorityFactory do
  it_behaves_like 'Import::Factory'

  it 'imports records' do

    import_data = {
      name: 'test',
    }
    expect(::Import::OTRS::Priority).to receive(:new).with(import_data)
    described_class.import([import_data])
  end

  it 'sets default create Priority' do
    priority                = ::Ticket::Priority.first
    priority.default_create = false
    priority.callback_loop  = true
    priority.save

    expect(Import::OTRS::SysConfigFactory).to receive(:postmaster_default_lookup).with(:priority_default_create).and_return(priority.name)

    described_class.update_attribute_settings
    priority.reload

    expect(priority.default_create).to be true
  end

  it "doesn't set default create Priority in diff import" do
    priority                = ::Ticket::Priority.first
    priority.default_create = false
    priority.callback_loop  = true
    priority.save

    expect(Import::OTRS).to receive(:diff?).and_return(true)

    described_class.update_attribute_settings
    priority.reload

    expect(priority.default_create).to be false
  end
end
