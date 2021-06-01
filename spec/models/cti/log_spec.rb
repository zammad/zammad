# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Cti::Log do
  subject(:user) { create(:user, roles: Role.where(name: 'Agent'), phone: phone) }

  let(:phone) { '' }
  let(:log) { create(:'cti/log') }

  describe '.log' do
    it 'returns a hash with :list and :assets keys' do
      expect(described_class.log(user)).to match(hash_including(:list, :assets))
    end

    context 'when pretty is not generated' do
      let(:log) { create(:'cti/log') }

      before do
        log.update_column(:preferences, nil)
      end

      it 'does fallback generate the pretty value' do
        expect(log.reload.attributes['from_pretty']).to eq('+49 30 609854180')
      end
    end

    context 'when over 60 Log records exist' do
      subject!(:cti_logs) do
        61.times.map do |_i| # rubocop:disable Performance/TimesMap
          travel 1.second
          create(:'cti/log')
        end
      end

      it 'returns the 60 latest ones in the :list key' do
        expect(described_class.log(user)[:list]).to match_array(cti_logs.last(60))
      end
    end

    context 'when Log records have arrays of CallerId attributes in #preferences[:to] / #preferences[:from]' do
      subject!(:cti_log) { create(:'cti/log', preferences: { from: [caller_id] }) }

      let(:caller_id) { create(:caller_id) }
      let(:caller_user) { User.find_by(id: caller_id.user_id) }

      it 'returns a hash of the CallerId Users and their assets in the :assets key' do
        expect(described_class.log(user)[:assets]).to eq(caller_user.assets({}))
      end
    end

    context 'when a notify map is defined' do
      subject!(:cti_logs) do
        [create(:'cti/log', queue: 'queue0'),
         create(:'cti/log', queue: 'queue2'),
         create(:'cti/log', queue: 'queue3'),
         create(:'cti/log', queue: 'queue4')]
      end

      before do
        cti_config = Setting.get('cti_config')
        cti_config[:notify_map] = [ { queue: 'queue4', user_ids: [user.id.to_s] } ]
        Setting.set('cti_config', cti_config)
      end

      it 'returns one matching log record' do

        expect(described_class.log(user)[:list]).to match_array([cti_logs[3]])
      end
    end

  end

  describe '.push_caller_list_update?' do
    let!(:existing_logs) { create_list(:'cti/log', 60) }
    let(:log) { create(:'cti/log') }

    context 'when given log is older than existing logs' do
      before { travel(-10.seconds) }

      it 'return false' do
        expect(described_class.push_caller_list_update?(log)).to eq false
      end
    end

    context 'when given log is newer than existing logs' do
      before { travel(10.seconds) }

      it 'return true' do
        expect(described_class.push_caller_list_update?(log)).to eq true
      end
    end
  end

  describe '.process' do
    let(:attributes) do
      {
        'cause'     => cause,
        'event'     => event,
        'user'      => 'user 1',
        'from'      => '49123456',
        'to'        => '49123457',
        'call_id'   => '1',
        'direction' => 'in',
      }
    end

    let(:cause) { '' }

    context 'for event "newCall"' do
      let(:event) { 'newCall' }

      context 'with unrecognized "call_id"' do
        it 'creates a new Log record' do
          expect { described_class.process(attributes) }
            .to change(described_class, :count).by(1)

          expect(described_class.last.attributes)
            .to include(
              'call_id'      => '1',
              'state'        => 'newCall',
              'done'         => false,
              'queue'        => '49123457',
              'from'         => '49123456',
              'from_comment' => nil,
              'from_pretty'  => '49123456',
              'start_at'     => nil,
              'end_at'       => nil,
              'to'           => '49123457',
              'to_comment'   => 'user 1',
              'to_pretty'    => '49123457'
            )
        end

        context 'for direction "in", with a CallerId record matching the "from" number' do
          let!(:caller_id) { create(:caller_id, caller_id: '49123456') }

          before { attributes.merge!('direction' => 'in') }

          it 'saves that CallerId’s attributes in the new Log’s #preferences[:from] attribute' do
            described_class.process(attributes)

            expect(described_class.last.preferences[:from].first)
              .to include(caller_id.attributes.except('created_at'))  # Checking equality of Time objects is error-prone
          end
        end

        context 'for direction "out", with a CallerId record matching the "to" number' do
          let!(:caller_id) { create(:caller_id, caller_id: '49123457') }

          before { attributes.merge!('direction' => 'out') }

          it 'saves that CallerId’s attributes in the new Log’s #preferences[:to] attribute' do
            described_class.process(attributes)

            expect(described_class.last.preferences[:to].first)
              .to include(caller_id.attributes.except('created_at'))  # Checking equality of Time objects is error-prone
          end
        end
      end

      context 'with recognized "call_id"' do
        before { create(:'cti/log', call_id: '1') }

        it 'raises an error' do
          expect { described_class.process(attributes) }.to raise_error(%r{call_id \S+ already exists!})
        end
      end
    end

    context 'for event "answer"' do
      let(:event) { 'answer' }

      context 'with unrecognized "call_id"' do
        it 'raises an error' do
          expect { described_class.process(attributes) }.to raise_error(%r{No such call_id})
        end
      end

      context 'with recognized "call_id"' do
        context 'for Log with #state "newCall"' do
          let(:log) { create(:'cti/log', call_id: 1, state: 'newCall', done: false) }

          it 'returns early with no changes' do
            expect { described_class.process(attributes) }
              .to change { log.reload.state }.to('answer')
              .and change { log.reload.done }.to(true)
          end
        end

        context 'for Log with #state "hangup"' do
          let(:log) { create(:'cti/log', call_id: 1, state: 'hangup', done: false) }

          it 'returns early with no changes' do
            expect { described_class.process(attributes) }
              .not_to change(log, :reload)
          end
        end
      end
    end

    context 'for event "hangup"' do
      let(:event) { 'hangup' }

      context 'with unrecognized "call_id"' do
        it 'raises an error' do
          expect { described_class.process(attributes) }.to raise_error(%r{No such call_id})
        end
      end

      context 'with recognized "call_id"' do
        context 'for Log with #state "newCall"' do
          let(:log) { create(:'cti/log', call_id: 1, state: 'newCall', done: false) }

          it 'sets attributes #state: "hangup", #done: false' do
            expect { described_class.process(attributes) }
              .to change { log.reload.state }.to('hangup')
              .and not_change { log.reload.done }
          end

          context 'when call is forwarded' do
            let(:cause) { 'forwarded' }

            it 'sets attributes #state: "hangup", #done: true' do
              expect { described_class.process(attributes) }
                .to change { log.reload.state }.to('hangup')
                .and change { log.reload.done }.to(true)
            end
          end
        end

        context 'for Log with #state "answer"' do
          let(:log) { create(:'cti/log', call_id: 1, state: 'answer', done: true) }

          it 'sets attributes #state: "hangup"' do
            expect { described_class.process(attributes) }
              .to change { log.reload.state }.to('hangup')
              .and not_change { log.reload.done }
          end

          context 'when call is sent to voicemail' do
            before { log.update(to_comment: 'voicemail') }

            it 'sets attributes #state: "hangup", #done: false' do
              expect { described_class.process(attributes) }
                .to change { log.reload.state }.to('hangup')
                .and change { log.reload.done }.to(false)
            end
          end
        end
      end
    end

    context 'for preferences.from verification' do
      subject(:log) do
        described_class.process(attributes)
      end

      let(:customer_of_ticket) { create(:customer) }
      let(:ticket_sample) do
        create(:ticket_article, created_by_id: customer_of_ticket.id, body: 'some text 0123457')
        TransactionDispatcher.commit
        Scheduler.worker(true)
      end
      let(:caller_id) { '0123456' }
      let(:attributes) do
        {
          'cause'     => '',
          'event'     => 'newCall',
          'user'      => 'user 1',
          'from'      => caller_id,
          'to'        => '49123450',
          'call_id'   => '1',
          'direction' => 'in',
        }
      end

      context 'with now related customer' do
        it 'gives no caller information' do
          expect(log.preferences[:from]).to eq(nil)
        end
      end

      context 'with related known customer' do
        let!(:customer) { create(:customer, phone: '0123456') }

        it 'gives caller information' do
          expect(log.preferences[:from].count).to eq(1)
          expect(log.preferences[:from].first)
            .to include(
              'level'   => 'known',
              'user_id' => customer.id,
            )
        end
      end

      context 'with related known customers' do
        let!(:customer1) { create(:customer, phone: '0123456') }
        let!(:customer2) { create(:customer, phone: '0123456') }

        it 'gives caller information' do
          expect(log.preferences[:from].count).to eq(2)
          expect(log.preferences[:from].first)
            .to include(
              'level'   => 'known',
              'user_id' => customer2.id,
            )
        end
      end

      context 'with related maybe customer' do
        let(:caller_id) { '0123457' }
        let!(:ticket) { ticket_sample }

        it 'gives caller information' do
          expect(log.preferences[:from].count).to eq(1)
          expect(log.preferences[:from].first)
            .to include(
              'level'   => 'maybe',
              'user_id' => customer_of_ticket.id,
            )
        end
      end

      context 'with related maybe and known customer' do
        let(:caller_id) { '0123457' }
        let!(:customer) { create(:customer, phone: '0123457') }
        let!(:ticket) { ticket_sample }

        it 'gives caller information' do
          expect(log.preferences[:from].count).to eq(1)
          expect(log.preferences[:from].first)
            .to include(
              'level'   => 'known',
              'user_id' => customer.id,
            )
        end
      end
    end
  end

  describe 'Callbacks -' do
    describe 'Updating agent sessions:' do
      before { allow(Sessions).to receive(:send_to).with(any_args) }

      context 'on creation' do
        it 'pushes "cti_list_push" event' do
          User.with_permissions('cti.agent').each do |u|
            expect(Sessions).to receive(:send_to).with(u.id, { event: 'cti_list_push' })
          end

          create(:cti_log)
        end

        context 'with over 60 existing Log records' do
          before { create_list(:cti_log, 60) }

          it '(always) pushes "cti_list_push" event' do
            User.with_permissions('cti.agent').each do |u|
              expect(Sessions).to receive(:send_to).with(u.id, { event: 'cti_list_push' })
            end

            create(:cti_log)
          end
        end
      end

      context 'on update' do
        subject!(:log) { create(:cti_log) }

        it 'pushes "cti_list_push" event' do
          User.with_permissions('cti.agent').each do |u|
            expect(Sessions).to receive(:send_to).with(u.id, { event: 'cti_list_push' })
          end

          log.touch
        end

        context 'when among the latest 60 Log records' do
          before { create_list(:cti_log, 59) }

          it 'pushes "cti_list_push" event' do
            User.with_permissions('cti.agent').each do |u|
              expect(Sessions).to receive(:send_to).with(u.id, { event: 'cti_list_push' })
            end

            log.touch
          end
        end

        context 'when not among the latest 60 Log records' do
          before { create_list(:cti_log, 60) }

          it 'does NOT push "cti_list_push" event' do
            User.with_permissions('cti.agent').each do |u|
              expect(Sessions).not_to receive(:send_to).with(u.id, { event: 'cti_list_push' })
            end

            log.touch
          end
        end
      end
    end
  end

  describe '#from_pretty' do
    context 'with complete, E164 international numbers' do
      subject(:log) { create(:cti_log, from: '4930609854180') }

      it 'gives the number in prettified format' do
        expect(log.from_pretty).to eq('+49 30 609854180')
      end
    end

    context 'with private network numbers' do
      subject(:log) { create(:cti_log, from: '007') }

      it 'gives the number unaltered' do
        expect(log.from_pretty).to eq('007')
      end
    end
  end

  describe '#to_pretty' do
    context 'with complete, E164 international numbers' do
      subject(:log) { create(:cti_log, to: '4930609811111') }

      it 'gives the number in prettified format' do
        expect(log.to_pretty).to eq('+49 30 609811111')
      end
    end

    context 'with private network numbers' do
      subject(:log) { create(:cti_log, to: '008') }

      it 'gives the number unaltered' do
        expect(log.to_pretty).to eq('008')
      end
    end
  end

  describe '.queues_of_user' do
    context 'without notify_map and no own phone number' do
      it 'gives an empty array' do
        expect(described_class.queues_of_user(user, Setting.get('cti_config'))).to eq([])
      end
    end

    context 'with notify_map and no own phone number' do
      before do
        cti_config = Setting.get('cti_config')
        cti_config[:notify_map] = [ { queue: 'queue4', user_ids: [user.id.to_s] } ]
        Setting.set('cti_config', cti_config)
      end

      it 'gives an array with queue' do
        expect(described_class.queues_of_user(user, Setting.get('cti_config'))).to eq(['queue4'])
      end
    end

    context 'with notify_map and with own phone number' do
      let(:phone) { '012345678' }

      before do
        cti_config = Setting.get('cti_config')
        cti_config[:notify_map] = [ { queue: 'queue4', user_ids: [user.id.to_s] } ]
        Setting.set('cti_config', cti_config)
      end

      it 'gives an array with queue and phone number' do
        expect(described_class.queues_of_user(user, Setting.get('cti_config'))).to eq(%w[queue4 4912345678])
      end
    end
  end

  describe '#best_customer_id_of_log_entry' do
    subject(:log1) do
      described_class.process(
        'event'     => 'newCall',
        'user'      => 'user 1',
        'from'      => '01234599',
        'to'        => '49123450',
        'call_id'   => '1',
        'direction' => 'in',
      )
    end

    let!(:agent1) { create(:agent, phone: '01234599') }
    let!(:customer2) { create(:customer, phone: '') }
    let!(:ticket_article1) { create(:ticket_article, created_by_id: customer2.id, body: 'some text 01234599') }

    context 'with agent1 (known), customer1 (known) and customer2 (maybe)' do
      let!(:customer1) { create(:customer, phone: '01234599') }

      it 'gives customer1' do
        expect(log1.best_customer_id_of_log_entry).to eq(customer1.id)
      end
    end

    context 'with agent1 (known) and customer2 (maybe)' do
      it 'gives customer2' do
        expect(log1.best_customer_id_of_log_entry).to eq(agent1.id)
      end
    end
  end

  describe '#to_json' do
    it 'includes virtual attributes' do
      expect(log.as_json).to include('from_pretty', 'to_pretty')
    end
  end
end
