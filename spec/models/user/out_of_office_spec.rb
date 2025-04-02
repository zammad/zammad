# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe User::OutOfOffice, type: :model do
  subject(:user) { create(:user) }

  let(:agent)    { create(:agent) }

  describe 'Instance methods:' do
    describe '#out_of_office?' do
      context 'without any out_of_office_* attributes set' do
        it 'returns false' do
          expect(agent.out_of_office?).to be(false)
        end
      end

      context 'with valid #out_of_office_* attributes' do
        before do
          agent.update(
            out_of_office_start_at:       Time.current.yesterday,
            out_of_office_end_at:         Time.current.tomorrow,
            out_of_office_replacement_id: 1
          )
        end

        context 'when #out_of_office: false' do
          before { agent.update(out_of_office: false) }

          it 'returns false' do
            expect(agent.out_of_office?).to be(false)
          end
        end

        context 'when #out_of_office: true' do
          before { agent.update(out_of_office: true) }

          it 'returns true' do
            expect(agent.out_of_office?).to be(true)
          end

          context 'when the #out_of_office_end_at time has passed' do
            before { travel 2.days  }

            it 'returns false (even though #out_of_office has not changed)' do
              expect(agent).to have_attributes(
                out_of_office:  true,
                out_of_office?: false
              )
            end
          end
        end
      end

      context 'when date range is inclusive' do
        before do
          freeze_time

          agent.update(
            out_of_office:                true,
            out_of_office_start_at:       1.day.from_now.to_date,
            out_of_office_end_at:         1.week.from_now.to_date,
            out_of_office_replacement_id: 1
          )
        end

        it 'today in office' do
          expect(agent).not_to be_out_of_office
        end

        it 'tomorrow not in office' do
          travel_to 1.day.from_now # travel to specific date instead of moving a duration to deal with DST switches
          expect(agent).to be_out_of_office
        end

        it 'after 7 days not in office' do
          travel_to 7.days.from_now # travel to specific date instead of moving a duration to deal with DST switches
          expect(agent).to be_out_of_office
        end

        it 'after 8 days in office' do
          travel_to 8.days.from_now # travel to specific date instead of moving a duration to deal with DST switches
          expect(agent).not_to be_out_of_office
        end
      end

      # https://github.com/zammad/zammad/issues/3590
      context 'when setting the same date' do
        before do
          freeze_time

          target_date = 1.day.from_now.to_date
          agent.update(
            out_of_office:                true,
            out_of_office_start_at:       target_date,
            out_of_office_end_at:         target_date,
            out_of_office_replacement_id: 1
          )
        end

        it 'agent is out of office tomorrow' do
          travel 1.day
          expect(agent).to be_out_of_office
        end

        it 'agent is not out of office the day after tomorrow' do
          travel 2.days
          expect(agent).not_to be_out_of_office
        end

        it 'agent is not out of office today' do
          expect(agent).not_to be_out_of_office
        end

        describe 'it respects system time zone' do
          before do
            travel_to Time.current.end_of_day
          end

          it 'agent is in office if in UTC' do
            expect(agent).not_to be_out_of_office
          end

          it 'agent is out of office if ahead of UTC' do
            travel_to Time.current.end_of_day
            Setting.set('timezone_default', 'Europe/Vilnius')

            expect(agent).to be_out_of_office
          end
        end
      end
    end

    describe '#someones_out_of_office_replacement?' do
      it 'returns true when is replacing someone' do
        create(:agent).update!(
          out_of_office:                true,
          out_of_office_start_at:       1.day.ago,
          out_of_office_end_at:         1.day.from_now,
          out_of_office_replacement_id: user.id,
        )

        expect(user).to be_someones_out_of_office_replacement
      end

      it 'returns false when is not replacing anyone' do
        expect(user).not_to be_someones_out_of_office_replacement
      end
    end

    describe '#out_of_office_agent' do
      it { is_expected.to respond_to(:out_of_office_agent) }

      context 'when user has no designated substitute' do
        it 'returns nil' do
          expect(user.out_of_office_agent).to be_nil
        end
      end

      context 'when user has designated substitute' do
        subject(:user) do
          create(:user,
                 out_of_office:                out_of_office,
                 out_of_office_start_at:       Time.zone.yesterday,
                 out_of_office_end_at:         Time.zone.tomorrow,
                 out_of_office_replacement_id: substitute.id,)
        end

        let(:substitute) { create(:user) }

        context 'when is not out of office' do
          let(:out_of_office) { false }

          it 'returns nil' do
            expect(user.out_of_office_agent).to be_nil
          end
        end

        context 'when is out of office' do
          let(:out_of_office) { true }

          it 'returns the designated substitute' do
            expect(user.out_of_office_agent).to eq(substitute)
          end
        end

        context 'with recursive out of office structure' do
          let(:out_of_office) { true }
          let(:substitute) do
            create(:user,
                   out_of_office:                out_of_office,
                   out_of_office_start_at:       Time.zone.yesterday,
                   out_of_office_end_at:         Time.zone.tomorrow,
                   out_of_office_replacement_id: user_active.id,)
          end
          let!(:user_active) { create(:user) }

          it 'returns the designated substitute recursive' do
            expect(user.out_of_office_agent).to eq(user_active)
          end
        end

        context 'with recursive out of office structure with a endless loop' do
          let(:out_of_office) { true }
          let(:substitute) do
            create(:user,
                   out_of_office:                out_of_office,
                   out_of_office_start_at:       Time.zone.yesterday,
                   out_of_office_end_at:         Time.zone.tomorrow,
                   out_of_office_replacement_id: user_active.id,)
          end
          let!(:user_active) do
            create(:user,
                   out_of_office:                out_of_office,
                   out_of_office_start_at:       Time.zone.yesterday,
                   out_of_office_end_at:         Time.zone.tomorrow,
                   out_of_office_replacement_id: agent.id,)
          end

          before do
            user_active.update(out_of_office_replacement_id: substitute.id)
          end

          it 'returns the designated substitute recursive with a endless loop' do
            expect(user.out_of_office_agent).to eq(substitute)
          end
        end

        context 'with stack depth exceeding limit' do
          let(:replacement_chain) do
            user = create(:agent)

            14
              .times
              .each_with_object([user]) do |_, memo|
                memo << create(:agent, :ooo, ooo_agent: memo.last)
              end
              .reverse
          end

          let(:ids_executed) { [] }

          before do
            allow_any_instance_of(User).to receive(:out_of_office_agent).and_wrap_original do |method, **kwargs|
              ids_executed << method.receiver.id
              method.call(**kwargs)
            end

            allow(Rails.logger).to receive(:warn)
          end

          it 'returns the last agent at the limit' do
            expect(replacement_chain.first.out_of_office_agent).to eq replacement_chain[10]
          end

          it 'does not evaluate element beyond the limit' do
            user_beyond_limit = replacement_chain[11]

            replacement_chain.first.out_of_office_agent

            expect(ids_executed).not_to include(user_beyond_limit.id)
          end

          it 'does evaluate element within the limit' do
            user_within_limit = replacement_chain[5]

            replacement_chain.first.out_of_office_agent

            expect(ids_executed).to include(user_within_limit.id)
          end

          it 'logs error below the limit' do
            replacement_chain.first.out_of_office_agent

            expect(Rails.logger).to have_received(:warn).with(%r{#{Regexp.escape('Found more than 10 replacement levels for agent')}})
          end

          it 'does not logs warn within the limit' do
            replacement_chain[10].out_of_office_agent

            expect(Rails.logger).not_to have_received(:warn)
          end
        end
      end
    end

    describe '#out_of_office_agent_of' do
      context 'when no other agents are out-of-office' do
        it 'returns an empty ActiveRecord::Relation' do
          expect(agent.out_of_office_agent_of)
            .to be_an(ActiveRecord::Relation)
            .and be_empty
        end
      end

      context 'when designated as the substitute' do
        let!(:agent_on_holiday) do
          create(
            :agent,
            out_of_office_start_at:       Time.current.yesterday,
            out_of_office_end_at:         Time.current.tomorrow,
            out_of_office_replacement_id: agent.id,
            out_of_office:                out_of_office
          )
        end

        context 'with an in-office agent' do
          let(:out_of_office) { false }

          it 'returns an empty ActiveRecord::Relation' do
            expect(agent.out_of_office_agent_of)
              .to be_an(ActiveRecord::Relation)
              .and be_empty
          end
        end

        context 'with an out-of-office agent' do
          let(:out_of_office) { true }

          it 'returns an ActiveRecord::Relation including that agent' do
            expect(agent.out_of_office_agent_of)
              .to contain_exactly(agent_on_holiday)
          end
        end

        context 'when inherited' do
          let(:out_of_office) { true }
          let!(:agent_on_holiday_sub) do
            create(
              :agent,
              out_of_office_start_at:       Time.current.yesterday,
              out_of_office_end_at:         Time.current.tomorrow,
              out_of_office_replacement_id: agent_on_holiday.id,
              out_of_office:                out_of_office
            )
          end

          it 'returns an ActiveRecord::Relation including both agents' do
            expect(agent.out_of_office_agent_of)
              .to contain_exactly(agent_on_holiday, agent_on_holiday_sub)
          end
        end

        context 'when inherited endless loop' do
          let(:out_of_office) { true }
          let!(:agent_on_holiday_sub) do
            create(
              :agent,
              out_of_office_start_at:       Time.current.yesterday,
              out_of_office_end_at:         Time.current.tomorrow,
              out_of_office_replacement_id: agent_on_holiday.id,
              out_of_office:                out_of_office
            )
          end
          let!(:agent_on_holiday_sub2) do
            create(
              :agent,
              out_of_office_start_at:       Time.current.yesterday,
              out_of_office_end_at:         Time.current.tomorrow,
              out_of_office_replacement_id: agent_on_holiday_sub.id,
              out_of_office:                out_of_office
            )
          end

          before do
            agent_on_holiday_sub.update(out_of_office_replacement_id: agent_on_holiday_sub2.id)
          end

          it 'returns an ActiveRecord::Relation including both agents referencing each other' do
            expect(agent_on_holiday_sub.out_of_office_agent_of)
              .to contain_exactly(agent_on_holiday_sub, agent_on_holiday_sub2)
          end
        end
      end
    end
  end
end
