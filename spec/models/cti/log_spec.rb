require 'rails_helper'

RSpec.describe Cti::Log do
  subject(:log) { create(:'cti/log') }

  describe '.log' do
    it 'returns a hash with :list and :assets keys' do
      expect(Cti::Log.log).to be_a(Hash).and include(:list, :assets)
    end

    context 'when over 60 Log records exist' do
      subject!(:cti_logs) { create_list(:'cti/log', 61) }

      it 'returns the 60 latest ones in the :list key' do
        expect(Cti::Log.log[:list]).to match_array(cti_logs.last(60))
      end
    end

    context 'when Log records have arrays of CallerId attributes in #preferences[:to] / #preferences[:from]' do
      subject!(:cti_log) { create(:'cti/log', preferences: { from: [caller_id] }) }
      let(:caller_id) { create(:caller_id) }
      let(:user) { User.find_by(id: caller_id.user_id) }

      it 'returns a hash of the CallerId Users and their assets in the :assets key' do
        expect(Cti::Log.log[:assets]).to eq(user.assets({}))
      end
    end
  end

  describe '.process' do
    let(:attributes) do
      {
        'cause'     => '',
        'event'     => event,
        'user'      => 'user 1',
        'from'      => '49123456',
        'to'        => '49123457',
        'call_id'   => '1',
        'direction' => 'in',
      }
    end

    context 'for event "newCall"' do
      let(:event) { 'newCall' }

      context 'with unrecognized "call_id"' do
        it 'creates a new Log record (#state: "newCall", #done: false)' do
          expect { Cti::Log.process(attributes) }
            .to change { Cti::Log.count }.by(1)

          expect(Cti::Log.last.attributes)
            .to include('state' => 'newCall', 'done' => false)
        end

        context 'for direction "in", with a CallerId record matching the "from" number' do
          let!(:caller_id) { create(:caller_id, caller_id: '49123456') }
          before { attributes.merge!('direction' => 'in') }

          it 'saves that CallerId’s attributes in the new Log’s #preferences[:from] attribute' do
            Cti::Log.process(attributes)

            expect(Cti::Log.last.preferences[:from].first)
              .to include(caller_id.attributes.except('created_at'))  # Checking equality of Time objects is error-prone
          end
        end

        context 'for direction "out", with a CallerId record matching the "to" number' do
          let!(:caller_id) { create(:caller_id, caller_id: '49123457') }
          before { attributes.merge!('direction' => 'out') }

          it 'saves that CallerId’s attributes in the new Log’s #preferences[:to] attribute' do
            Cti::Log.process(attributes)

            expect(Cti::Log.last.preferences[:to].first)
              .to include(caller_id.attributes.except('created_at'))  # Checking equality of Time objects is error-prone
          end
        end
      end

      context 'with recognized "call_id"' do
        before { create(:'cti/log', call_id: '1') }

        it 'raises an error' do
          expect { Cti::Log.process(attributes) }.to raise_error(/call_id \S+ already exists!/)
        end
      end
    end

    context 'for event "answer"' do
      let(:event) { 'answer' }

      context 'with unrecognized "call_id"' do
        it 'raises an error' do
          expect { Cti::Log.process(attributes) }.to raise_error(/No such call_id/)
        end
      end

      context 'with recognized "call_id"' do
        context 'for Log with #state "hangup"' do
          let(:log) { create(:'cti/log', call_id: 1, state: 'hangup', done: false) }

          it 'returns early with no changes' do
            expect { Cti::Log.process(attributes) }
              .not_to change { log.reload }
          end
        end
      end
    end

    context 'for event "hangup"' do
      let(:event) { 'hangup' }

      context 'with unrecognized "call_id"' do
        it 'raises an error' do
          expect { Cti::Log.process(attributes) }.to raise_error(/No such call_id/)
        end
      end

      context 'with recognized "call_id"' do
        context 'for Log with #state "newCall"' do
          let(:log) { create(:'cti/log', call_id: 1, done: true) }

          it 'sets attributes #state: "hangup", #done: false' do
            expect { Cti::Log.process(attributes) }
              .to change { log.reload.state }.to('hangup').and change { log.reload.done }.to(false)
          end
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

  describe '#to_json' do
    it 'includes virtual attributes' do
      expect(log.as_json).to include('from_pretty', 'to_pretty')
    end
  end
end
