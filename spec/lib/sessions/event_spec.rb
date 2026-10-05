# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Event do
  describe 'database connection requirement flag' do
    it 'is not set for the event base class' do
      expect(Sessions::Event::Base.instance_variable_get(:@database_connection)).to be_nil
    end

    it 'is set for chat events' do
      expect(Sessions::Event::ChatBase.instance_variable_get(:@database_connection)).to be(true)
    end

    it 'is set for chat agent status events' do
      expect(Sessions::Event::ChatStatusAgent.instance_variable_get(:@database_connection)).to be(true)
    end
  end

  # check if db connection is available for chat events
  # see: https://github.com/zammad/zammad/issues/2353
  describe '.run database connection handling' do
    let(:websocket) do
      Class.new do
        def send(msg) # rubocop:disable Zammad/ForbidDefSend
          Rails.logger.info "WS send: #{msg}"
        end
      end.new
    end

    def run_event(event, client = nil)
      described_class.run(
        event:     event,
        payload:   {},
        session:   {},
        client_id: '123',
        client:    client,
        options:   {},
      )
    end

    context 'with a websocket connection and no established database connection' do
      # Disable transactional tests because the examples remove
      # and re-establish the database connection.
      self.use_transactional_tests = false

      before do
        ActiveRecord::Base.remove_connection
      end

      after do
        ActiveRecord::Base.establish_connection
      end

      it 'removes the database connection again after a login event', :aggregate_failures do
        message = run_event('login', { websocket: websocket })

        expect(message).to be(false)
        expect { User.first }.to raise_error(ActiveRecord::ConnectionNotEstablished)
      end

      it 'removes the database connection again after a chat event', :aggregate_failures do
        message = run_event('chat_status_customer', { websocket: websocket })

        expect(message[:event]).to eq('chat_error')
        expect { User.first }.to raise_error(ActiveRecord::ConnectionNotEstablished)
      end

      it 'removes the database connection again after a failing event', :aggregate_failures do
        stub_const('Sessions::Event::SpecFailingWithConnection', Class.new(Sessions::Event::Base) do
          database_connection_required

          def run
            raise 'failing event'
          end
        end)

        message = run_event('spec_failing_with_connection', { websocket: websocket })

        expect(message[:event]).to eq('error')
        expect { User.first }.to raise_error(ActiveRecord::ConnectionNotEstablished)
      end
    end

    context 'with ajax long polling' do
      it 'keeps the database connection after a login event', :aggregate_failures do
        message = run_event('login')

        expect(message).to be(false)
        expect { User.first }.not_to raise_error
      end

      it 'keeps the database connection after a chat event', :aggregate_failures do
        message = run_event('chat_status_customer')

        expect(message[:event]).to eq('chat_error')
        expect { User.first }.not_to raise_error
      end
    end
  end

  describe '.run error handling' do
    let(:secret)  { 'super-secret-session-cookie' }
    let(:headers) { { 'Cookie' => "_zammad_session=#{secret}" } }
    let(:client)  { { websocket: nil, headers: headers } }
    let(:payload) { { 'event' => event } }

    let(:result) do
      described_class.run(
        event:     event,
        payload:   payload,
        session:   { 'id' => 1 },
        headers:   headers,
        client_id: '123',
        client:    client,
        options:   {},
      )
    end

    let(:logged_errors) do
      [].tap do |messages|
        allow(Rails.logger).to receive(:error) { |message = nil, &block| messages << (block ? block.call : message) }
      end
    end

    shared_examples 'returning a generic error' do
      it 'returns a generic error without internal state', :aggregate_failures do
        expect(result).to eq({ event: 'error', data: { error: 'The event could not be processed.', payload: payload } })
        expect(result.to_json).not_to include(secret)
      end

      it 'logs the details on the server side' do
        logged_errors

        result

        expect(logged_errors).to be_present
      end
    end

    context 'with an unknown event name' do
      let(:event) { 'not_existing_event' }

      it_behaves_like 'returning a generic error'
    end

    context 'with a malformed event name' do
      let(:event) { '../../object' }

      it_behaves_like 'returning a generic error'
    end

    # Without the name check this would resolve and dispatch `Ping`.
    context 'with an event name of a real event in the wrong case' do
      let(:event) { 'Ping' }

      it_behaves_like 'returning a generic error'
    end

    context 'with a non-string event name' do
      let(:event) { { 'nested' => 'event' } }

      it_behaves_like 'returning a generic error'
    end

    # `constantize` does not walk up to the top-level constant, so 'object'
    # resolves nothing instead of resolving `Object`.
    context 'with a name that only exists outside the event namespace' do
      let(:event) { 'object' }

      it_behaves_like 'returning a generic error'
    end

    context 'with a constant that is not a class' do
      let(:event) { 'spec_not_a_class' }

      before do
        stub_const('Sessions::Event::SpecNotAClass', Module.new)
      end

      it_behaves_like 'returning a generic error'
    end

    # The class implements the complete interface of a dispatchable event, so
    # only its missing ancestry keeps it from being dispatched. Without that
    # check the result would be the return value of its `run` method.
    context 'with a class that is not an event class' do
      let(:event) { 'spec_not_an_event' }

      before do
        stub_const('Sessions::Event::SpecNotAnEvent', Class.new do
          def self.abstract_event?
            false
          end

          def initialize(**); end

          def run
            'not an event'
          end

          def destroy; end
        end)
      end

      it_behaves_like 'returning a generic error'
    end

    context 'with an event class that does not implement run' do
      let(:event) { 'spec_without_run' }

      before do
        stub_const('Sessions::Event::SpecWithoutRun', Class.new(Sessions::Event::Base))
      end

      it_behaves_like 'returning a generic error'

      it 'does not instantiate the class' do
        allow(Sessions::Event::SpecWithoutRun).to receive(:new)

        result

        expect(Sessions::Event::SpecWithoutRun).not_to have_received(:new)
      end
    end

    context 'with the abstract base event name' do
      let(:event) { 'base' }

      it_behaves_like 'returning a generic error'

      it 'does not instantiate the abstract event class' do
        allow(Sessions::Event::Base).to receive(:new)

        result

        expect(Sessions::Event::Base).not_to have_received(:new)
      end
    end

    context 'with an abstract chat event name' do
      let(:event) { 'chat_base' }

      it_behaves_like 'returning a generic error'
    end

    # The following two examples raise from `abstract_event?` to fail inside the
    # class resolution itself, which rescues `StandardError` and `LoadError`
    # because `safe_constantize` re-raises both while loading a class.
    context 'with an event class that raises while it is resolved' do
      let(:event) { 'spec_unresolvable' }

      before do
        stub_const('Sessions::Event::SpecUnresolvable', Class.new(Sessions::Event::Base) do
          def self.abstract_event?
            raise 'resolving failed'
          end
        end)
      end

      it_behaves_like 'returning a generic error'
    end

    context 'with an event class that cannot be loaded' do
      let(:event) { 'spec_unloadable' }

      before do
        stub_const('Sessions::Event::SpecUnloadable', Class.new(Sessions::Event::Base) do
          def self.abstract_event?
            raise LoadError, 'loading failed'
          end
        end)
      end

      it_behaves_like 'returning a generic error'
    end

    context 'with an event handler that raises' do
      let(:event) { 'spec_failing' }

      before do
        stub_const('Sessions::Event::SpecFailing', Class.new(Sessions::Event::Base) do
          def run
            raise "failing with internal state #{@headers.inspect}"
          end
        end)
      end

      it_behaves_like 'returning a generic error'

      it 'keeps the exception details in the server side log only', :aggregate_failures do
        logged_errors

        expect(result.to_json).not_to include('failing with internal state')
        expect(logged_errors.join("\n")).to include('failing with internal state')
      end
    end
  end
end
