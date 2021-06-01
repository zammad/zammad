# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Number do
  let(:stubbed_subclass) { double('Foo') }

  before { stub_const('Ticket::Number::Foo', stubbed_subclass) }

  describe '.generate' do
    before { Setting.set('ticket_number', 'Ticket::Number::Foo') }

    it 'defers to subclass specified in "ticket_number" setting' do
      expect(Ticket::Number::Foo).to receive(:generate)
      expect(described_class.generate).to be(nil)
    end
  end

  describe '.check' do
    before { Setting.set('ticket_number', 'Ticket::Number::Foo') }

    it 'defers to subclass specified in "ticket_number" setting' do
      expect(Ticket::Number::Foo).to receive(:check).with('foo')
      expect(described_class.check('foo')).to be(nil)
    end
  end

  describe '.adapter' do
    it 'defaults to Ticket::Number::Increment' do
      expect(described_class.adapter).to be(Ticket::Number::Increment)
    end

    it 'depends on "ticket_number" setting' do
      expect { Setting.set('ticket_number', 'Ticket::Number::Foo') }
        .to change(described_class, :adapter).to(Ticket::Number::Foo)
    end
  end
end
