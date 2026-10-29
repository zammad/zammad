# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Number do
  let(:stubbed_subclass) do
    Module.new do
      def self.generate; end
      def self.check(_string); end
    end
  end

  before { stub_const('Ticket::Number::Foo', stubbed_subclass) }

  describe '.generate' do
    before { Setting.set('ticket_number', 'Ticket::Number::Foo', validate: false) }

    it 'defers to subclass specified in "ticket_number" setting' do
      expect(Ticket::Number::Foo).to receive(:generate)
      expect(described_class.generate).to be_nil
    end
  end

  describe '.check' do
    before { Setting.set('ticket_number', 'Ticket::Number::Foo', validate: false) }

    it 'defers to subclass specified in "ticket_number" setting' do
      expect(Ticket::Number::Foo).to receive(:check).with('foo')
      expect(described_class.check('foo')).to be_nil
    end
  end

  describe '.adapter' do
    it 'defaults to Ticket::Number::Increment' do
      expect(described_class.adapter).to be(Ticket::Number::Increment)
    end

    it 'depends on "ticket_number" setting' do
      expect { Setting.set('ticket_number', 'Ticket::Number::Foo', validate: false) }
        .to change(described_class, :adapter).to(Ticket::Number::Foo)
    end

    context 'when the setting names a class outside of Ticket::Number' do
      before do
        Setting.set('ticket_number', 'JSON', validate: false)
        allow(JSON).to receive(:generate)
      end

      it 'does not use it', :aggregate_failures do
        expect { described_class.generate }.to raise_error(RuntimeError, "The setting 'ticket_number' names 'JSON', which is not a ticket number generator.")
        expect(JSON).not_to have_received(:generate)
      end
    end

    context 'when the setting is blank' do
      before { Setting.set('ticket_number', '', validate: false) }

      it 'raises' do
        expect { described_class.adapter }.to raise_error(RuntimeError, "The setting 'ticket_number' was not configured.")
      end
    end
  end
end
