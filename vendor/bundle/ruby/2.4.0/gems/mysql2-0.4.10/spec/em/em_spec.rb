# encoding: UTF-8
require 'spec_helper'
begin
  require 'eventmachine'
  require 'mysql2/em'

  RSpec.describe Mysql2::EM::Client do
    it "should support async queries" do
      results = []
      EM.run do
        client1 = Mysql2::EM::Client.new DatabaseCredentials['root']
        defer1 = client1.query "SELECT sleep(0.1) as first_query"
        defer1.callback do |result|
          results << result.first
          client1.close
          EM.stop_event_loop
        end

        client2 = Mysql2::EM::Client.new DatabaseCredentials['root']
        defer2 = client2.query "SELECT sleep(0.025) second_query"
        defer2.callback do |result|
          results << result.first
          client2.close
        end
      end

      expect(results[0].keys).to include("second_query")
      expect(results[1].keys).to include("first_query")
    end

    it "should support queries in callbacks" do
      results = []
      EM.run do
        client = Mysql2::EM::Client.new DatabaseCredentials['root']
        defer1 = client.query "SELECT sleep(0.025) as first_query"
        defer1.callback do |result|
          results << result.first
          defer2 = client.query "SELECT sleep(0.025) as second_query"
          defer2.callback do |r|
            results << r.first
            client.close
            EM.stop_event_loop
          end
        end
      end

      expect(results[0].keys).to include("first_query")
      expect(results[1].keys).to include("second_query")
    end

    it "should not swallow exceptions raised in callbacks" do
      expect {
        EM.run do
          client = Mysql2::EM::Client.new DatabaseCredentials['root']
          defer = client.query "SELECT sleep(0.1) as first_query"
          defer.callback do
            client.close
            fail 'some error'
          end
          defer.errback do
            # This _shouldn't_ be run, but it needed to prevent the specs from
            # freezing if this test fails.
            EM.stop_event_loop
          end
        end
      }.to raise_error('some error')
    end

    context 'when an exception is raised by the client' do
      let(:client) { Mysql2::EM::Client.new DatabaseCredentials['root'] }
      let(:error) { StandardError.new('some error') }
      before { allow(client).to receive(:async_result).and_raise(error) }
      after { client.close }

      it "should swallow exceptions raised in by the client" do
        errors = []
        EM.run do
          defer = client.query "SELECT sleep(0.1) as first_query"
          defer.callback do
            # This _shouldn't_ be run, but it is needed to prevent the specs from
            # freezing if this test fails.
            EM.stop_event_loop
          end
          defer.errback do |err|
            errors << err
            EM.stop_event_loop
          end
        end
        expect(errors).to eq([error])
      end

      it "should fail the deferrable" do
        callbacks_run = []
        EM.run do
          defer = client.query "SELECT sleep(0.025) as first_query"
          EM.add_timer(0.1) do
            defer.callback do
              callbacks_run << :callback
              # This _shouldn't_ be run, but it is needed to prevent the specs from
              # freezing if this test fails.
              EM.stop_event_loop
            end
            defer.errback do
              callbacks_run << :errback
              EM.stop_event_loop
            end
          end
        end
        expect(callbacks_run).to eq([:errback])
      end
    end

    it "should not raise error when closing client with no query running" do
      callbacks_run = []
      EM.run do
        client = Mysql2::EM::Client.new DatabaseCredentials['root']
        defer = client.query("select sleep(0.025)")
        defer.callback do
          callbacks_run << :callback
        end
        defer.errback do
          callbacks_run << :errback
        end
        EM.add_timer(0.1) do
          expect(callbacks_run).to eq([:callback])
          expect {
            client.close
          }.not_to raise_error
          EM.stop_event_loop
        end
      end
    end
  end
rescue LoadError
  puts "EventMachine not installed, skipping the specs that use it"
end
