# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormUpdater::OptionCache, :aggregate_failures, form_updater_option_cache_verification: false do
  let(:builds) { [] }

  # @param key_reads [Array] what the list is built from as it reads on the way: before the list is built, and after
  def fetch(key, options = [{ value: 1, label: 'Support' }], key_reads: [key, key])
    key_reads = key_reads.dup
    build     = proc do
      builds << key

      options
    end

    described_class.fetch(key, -> { key_reads.shift }, &build)
  end

  describe '.fetch' do
    it 'builds a list once for the same key, and again for another' do
      expect(fetch(['Group', [1, 2], '2-1'])).to eq([[{ value: 1, label: 'Support' }], ['Group', [1, 2], '2-1']])
      expect(fetch(['Group', [1, 2], '2-1'], [{ value: 1, label: 'Renamed' }])).to eq([[{ value: 1, label: 'Support' }], ['Group', [1, 2], '2-1']])
      expect(fetch(['Group', [1, 2], '2-2'], [{ value: 1, label: 'Renamed' }])).to eq([[{ value: 1, label: 'Renamed' }], ['Group', [1, 2], '2-2']])

      expect(builds.size).to eq(2)
    end

    it 'keeps an empty list as well' do
      2.times { fetch(['Group', [], '0'], []) }

      expect(builds.size).to eq(1)
    end

    it 'builds a list without a key every time, and no key stands for it' do
      expect(Array.new(2) { fetch(nil) }).to all(eq([[{ value: 1, label: 'Support' }], nil]))

      expect(builds.size).to eq(2)
    end

    it 'keeps a list under the key as it reads where the list is built, not as it read before' do
      narrow = ['Group', [1], '2-1']
      wide   = ['Group', [1, 2], '2-1']
      both   = [{ value: 1, label: 'Support' }, { value: 2, label: 'Sales' }]

      expect(fetch(narrow, both, key_reads: [wide, wide])).to eq([both, wide])
      expect(fetch(wide)).to eq([both, wide])
      expect(fetch(narrow)).to eq([[{ value: 1, label: 'Support' }], narrow])

      expect(builds.size).to eq(2)
    end

    it 'does not keep a list where its key reads differently after the list was built' do
      narrow = ['Group', [1], '2-1']
      wide   = ['Group', [1, 2], '2-1']

      expect(fetch(narrow, key_reads: [narrow, wide])).to eq([[{ value: 1, label: 'Support' }], nil])

      2.times { fetch(narrow) }
      fetch(wide)

      expect(builds.size).to eq(3)
    end

    # Transactional tests pin every thread to one connection.
    context 'with records changed over another connection' do
      self.use_transactional_tests = false

      let(:priority) { Ticket::Priority.where(active: true, default_create: false).reorder(:id).first }

      before { on_another_connection { priority.update!(active: false) } }

      after { priority.update!(active: true) }

      def on_another_connection(&)
        Thread.new do
          UserInfo.current_user_id = 1

          ActiveRecord::Base.connection_pool.with_connection(&)
        end.join
      end

      def priorities
        FormUpdater::Relation::TicketPriority.new(context: {}, current_user: nil)
      end

      # One request: the key is read, then the list is asked for, which reads the key again where it has to be built.
      #
      # @param before_list [Proc] runs once the key is read
      # @param in_between [Proc] runs once the key is read again for a list that has to be built
      # @param after_list [Proc] runs once the list is built
      def request(before_list: -> {}, in_between: -> {}, after_list: -> {})
        Rails.application.executor.wrap do
          key = priorities.options_key
          before_list.call

          key_source = -> { priorities.options_key.tap { in_between.call.then { in_between = -> {} } } }
          build      = proc { priorities.options.tap { after_list.call } }

          described_class.fetch(key, key_source, &build).first.pluck(:value)
        end
      end

      def switch(active)
        -> { on_another_connection { priority.update!(active:) } }
      end

      it 'answers a later request with its own list when a record was switched on before the list was built' do
        during = request(before_list: switch(true))
        switch(false).call

        expect(during).to include(priority.id)
        expect(request).not_to include(priority.id)
      end

      it 'answers a later request with its own list when a record was switched on and off again while the list was built' do
        during = request(in_between: switch(true), after_list: switch(false))

        expect(during).not_to include(priority.id)
        expect(request).not_to include(priority.id)
      end

      it 'answers a later request with its own list when a record was switched on while the list was built' do
        during = request(in_between: switch(true))

        expect(during).not_to include(priority.id)
        expect(request).to include(priority.id)
      end
    end
  end

  describe '.signature' do
    it 'is the same for the same key only, and none without one' do
      signature = described_class.signature(['Group', [1, 2], '2-1'])

      expect(described_class.signature(['Group', [1, 2], '2-1'])).to eq(signature)
      expect(described_class.signature(['Group', [1], '2-1'])).not_to eq(signature)
      expect(described_class.signature(nil)).to be_nil
    end
  end
end
