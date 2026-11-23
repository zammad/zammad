# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SearchIndexBackend::Reload, searchindex: true do
  let(:tickets) { create_list(:ticket, 8) }
  let(:steps)   { [] }

  def indexed_ids(index)
    SearchIndexBackend.refresh
    SearchIndexBackend.search('*', index, sort_by: ['id'], order_by: ['asc'], limit: 100).map { |item| item[:id].to_i }
  end

  # A model is finished with the first batch which is not full.
  def turns(model)
    (model.count / described_class::Records::BATCH_SIZE) + 1
  end

  def perform(models, worker: 0)
    described_class.new(models, worker:).perform do |records|
      steps << [records.model, records.count, records.finished?]
    end
  end

  before do
    tickets

    stub_const("#{described_class}::Records::BATCH_SIZE", 2)
  end

  describe '#perform' do
    it 'indexes the records with the highest id first' do
      indexed = nil

      described_class.new([Ticket]).perform do
        indexed ||= indexed_ids('Ticket')
      end

      expect(indexed).to eq(tickets.last(2).map(&:id))
    end

    it 'indexes a batch of every model in each turn', :aggregate_failures do
      perform([Ticket, Ticket::State])

      expect(steps.first(4)).to eq([[Ticket, 2, false], [Ticket::State, 2, false], [Ticket, 4, false], [Ticket::State, 4, false]])
      expect(indexed_ids('Ticket')).to eq(Ticket.reorder(:id).ids)
      expect(indexed_ids('Ticket::State')).to eq(Ticket::State.reorder(:id).ids)
    end

    it 'drops a model from the turns when it is finished', :aggregate_failures do
      perform([Ticket, Ticket::Priority])

      models = steps.map(&:first)

      expect(models.tally).to eq(Ticket => turns(Ticket), Ticket::Priority => turns(Ticket::Priority))
      expect(models.drop(turns(Ticket::Priority) * 2)).to all(eq(Ticket))
      expect(steps.last).to eq([Ticket, Ticket.count, true])
    end

    context 'when the number of records is a multiple of the batch size' do
      let(:tickets) { create_list(:ticket, 3) }

      it 'is finished after a batch without records', :aggregate_failures do
        expect(Ticket.count).to eq(4)

        perform([Ticket])

        expect(steps).to eq([[Ticket, 2, false], [Ticket, 4, false], [Ticket, 4, true]])
      end
    end

    context 'when a model has no records' do
      before do
        allow(SearchIndexBackend).to receive(:make_request).and_call_original
      end

      it 'is finished without a request', :aggregate_failures do
        perform([Chat::Session])

        expect(steps).to eq([[Chat::Session, 0, true]])
        expect(SearchIndexBackend).not_to have_received(:make_request)
      end
    end

    context 'when a record cannot be indexed' do
      before do
        allow(SearchIndexBackend).to receive(:make_request).and_return(UserAgent::Result.new(success: false, code: '400'))
        allow(SearchIndexBackend).to receive(:add).and_wrap_original do |_original, _type, data|
          raise 'broken record' if data['id'] == tickets.last.id
        end
      end

      it 'waits before it continues' do
        expect_any_instance_of(described_class::Records).to receive(:sleep).with(described_class::Records::RETRY_DELAY).once

        perform([Ticket])
      end
    end

    context 'when the caller has an active query cache' do
      def cached_ticket_queries
        count      = 0
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
          count += 1 if payload[:cached] && payload[:sql].include?('FROM "tickets"')
        end

        yield

        count
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      it 'loads the records from the database with every reload' do
        queries = cached_ticket_queries do
          Ticket.cache do
            2.times { described_class.new([Ticket]).perform }
          end
        end

        expect(queries).to be_zero
      end
    end

    context 'with workers' do
      let(:jobs)    { [] }
      let(:results) { [] }

      # Runs the jobs in this process, as a worker would take them one by one.
      before do
        allow(Process).to receive(:warmup)
        allow(Parallel).to receive(:each) do |producer, options, &block|
          while (job = producer.call) != Parallel::Stop
            jobs << job
            results << block.call(job)
            options[:finish].call(job, jobs.size, nil)
          end
        end
      end

      it 'loads all code and tidies the memory before the workers are started', :aggregate_failures do
        allow(Rails.application).to receive(:eager_load!)

        perform([Ticket], worker: 2)

        expect(Rails.application).to have_received(:eager_load!).ordered
        expect(Process).to have_received(:warmup).once.ordered
        expect(Parallel).to have_received(:each).ordered
      end

      it 'does not tidy the memory without workers' do
        perform([Ticket])

        expect(Process).not_to have_received(:warmup)
      end

      it 'gives every worker a part of a batch', :aggregate_failures do
        stub_const("#{described_class}::Records::BATCH_SIZE", 200)

        perform([Ticket], worker: 4)

        expect(Parallel).to have_received(:each).with(anything, include(in_processes: 4)).once
        expect(jobs.map { |_position, ids| ids.size }).to eq([3, 3, 3])
        expect(indexed_ids('Ticket')).to eq(Ticket.reorder(:id).ids)
      end

      it 'takes the slices of all models in turns' do
        perform([Ticket, Ticket::State], worker: 2)

        expect(jobs.first(4).map(&:first)).to eq([0, 0, 1, 1])
      end

      it 'replaces the workers after their number of records', :aggregate_failures do
        stub_const("#{described_class}::WORKER_LIFETIME", 4)

        perform([Ticket], worker: 2)

        expect(Parallel).to have_received(:each).exactly(3).times
        expect(indexed_ids('Ticket')).to eq(Ticket.reorder(:id).ids)
      end

      context 'when many records cannot be indexed' do
        let(:tickets) { create_list(:ticket, 11) }

        before do
          stub_const("#{described_class}::Records::BATCH_SIZE", 200)
          stub_const("#{described_class}::Records::RETRY_DELAY", 0)

          allow(SearchIndexBackend).to receive(:make_request).and_return(UserAgent::Result.new(success: false, code: '400'))
          allow(SearchIndexBackend).to receive(:add).and_raise('broken record')
          allow(Rails.logger).to receive(:error).and_call_original
        end

        it 'counts the failures of every slice on its own' do
          perform([Ticket], worker: 2)

          expect(Rails.logger).to have_received(:error).with(%r{Unable to send Ticket\.find}).exactly(12).times
        end

        it 'sends no records from the workers to the main process' do
          perform([Ticket], worker: 2)

          expect(results).to eq([nil, nil])
        end
      end
    end
  end
end
