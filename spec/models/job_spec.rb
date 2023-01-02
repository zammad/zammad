# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/has_timeplan_examples'

RSpec.describe Job, type: :model do
  subject(:job) { create(:job) }

  it_behaves_like 'ApplicationModel', can_assets: { selectors: %i[condition perform] }
  it_behaves_like 'HasXssSanitizedNote', model_factory: :job
  it_behaves_like 'HasTimeplan'

  describe 'validation' do
    it 'uses Validations::VerifyPerformRulesValidator' do
      expect(described_class).to have_validator(Validations::VerifyPerformRulesValidator).on(:perform)
    end
  end

  describe 'Class methods:' do
    describe '.run' do
      let!(:executable_jobs)    { jobs.select(&:executable?).select(&:in_timeplan?) }
      let!(:nonexecutable_jobs) { jobs - executable_jobs }

      let!(:jobs) do
        [
          # executable
          create(:job, :always_on, updated_at: 2.minutes.ago),

          # not executable (updated too recently)
          create(:job),

          # not executable (inactive)
          create(:job, updated_at: 2.minutes.ago, active: false),

          # not executable (started too recently)
          create(:job, :always_on, updated_at: 2.minutes.ago, last_run_at: 5.minutes.ago),

          # executable
          create(:job, :always_on, updated_at: 2.minutes.ago, last_run_at: 15.minutes.ago),

          # not executable (still running, started too recently)
          create(:job, :always_on, updated_at: 2.minutes.ago, running: true, last_run_at: 23.hours.ago),

          # executable
          create(:job, :always_on, updated_at: 2.minutes.ago, running: true, last_run_at: 25.hours.ago),
        ]
      end

      it 'runs all executable jobs (and no others)' do
        expect { described_class.run }
          .to change { executable_jobs.map(&:reload).map(&:last_run_at).any?(&:nil?) }.to(false)
          .and not_change { nonexecutable_jobs.map(&:reload).map(&:last_run_at).all?(&:nil?) }
      end
    end
  end

  describe 'Instance methods:' do
    describe '#run' do
      subject(:job) { create(:job, condition: condition, perform: perform) }

      let(:condition) do
        {
          'ticket.state_id'   => {
            'operator' => 'is',
            'value'    => Ticket::State.where(name: %w[new open]).pluck(:id).map(&:to_s)
          },
          'ticket.created_at' => {
            'operator' => 'before (relative)',
            'value'    => '2',
            'range'    => 'day'
          },
        }
      end

      let(:perform) do
        { 'ticket.state_id' => { 'value' => Ticket::State.find_by(name: 'closed').id.to_s } }
      end

      let!(:matching_ticket) do
        create(:ticket, state: Ticket::State.lookup(name: 'new'), created_at: 3.days.ago)
      end

      let!(:nonmatching_ticket) do
        create(:ticket, state: Ticket::State.lookup(name: 'new'), created_at: 1.day.ago)
      end

      context 'when job is not #executable?' do
        before { allow(job).to receive(:executable?).and_return(false) }

        it 'does not perform changes on matching tickets' do
          expect { job.run }.not_to change { matching_ticket.reload.state }
        end

        it 'does not update #last_run_at' do
          expect { job.run }.to not_change { job.reload.last_run_at }
        end

        context 'but "force" flag is given' do
          it 'performs changes on matching tickets' do
            expect { job.run(true) }
              .to change { matching_ticket.reload.state }
              .and not_change { nonmatching_ticket.reload.state }
          end

          it 'updates #last_run_at' do
            expect { job.run(true) }
              .to change { job.reload.last_run_at }
          end
        end
      end

      context 'when job is #executable?' do
        before { allow(job).to receive(:executable?).and_return(true) }

        context 'and due (#in_timeplan?)' do
          before { allow(job).to receive(:in_timeplan?).and_return(true) }

          it 'updates #last_run_at' do
            expect { job.run }.to change { job.reload.last_run_at }
          end

          it 'performs changes on matching tickets' do
            expect { job.run }
              .to change { matching_ticket.reload.state }
              .and not_change { nonmatching_ticket.reload.state }
          end

          context 'and already marked #running' do
            before { job.update(running: true) }

            it 'resets #running to false' do
              expect { job.run }.to change { job.reload.running }.to(false)
            end
          end

          context 'but condition doesn’t match any tickets' do
            before { job.update(condition: invalid_condition) }

            let(:invalid_condition) do
              { 'ticket.state_id' => { 'operator' => 'is', 'value' => '9999' } }
            end

            it 'performs no changes' do
              expect { job.run }
                .not_to change { matching_ticket.reload.state }
            end
          end

          describe 'use case: deleting tickets based on tag' do
            let(:condition) { { 'ticket.tags' => { 'operator' => 'contains one', 'value' => 'spam' } } }
            let(:perform)             { { 'ticket.action' => { 'value' => 'delete' } } }
            let!(:matching_ticket)    { create(:ticket).tap { |t| t.tag_add('spam', 1) } }
            let!(:nonmatching_ticket) { create(:ticket) }

            it 'deletes tickets matching the specified tags' do
              job.run

              expect { matching_ticket.reload }.to raise_error(ActiveRecord::RecordNotFound)
              expect { nonmatching_ticket.reload }.not_to raise_error
            end
          end

          describe 'use case: deleting tickets based on group' do
            let(:condition) { { 'ticket.group_id' => { 'operator' => 'is', 'value' => matching_ticket.group.id } } }
            let(:perform)             { { 'ticket.action' => { 'value' => 'delete' } } }
            let!(:matching_ticket)    { create(:ticket) }
            let!(:nonmatching_ticket) { create(:ticket) }

            it 'deletes tickets matching the specified groups' do
              job.run

              expect { matching_ticket.reload }.to raise_error(ActiveRecord::RecordNotFound)
              expect { nonmatching_ticket.reload }.not_to raise_error
            end
          end
        end

        context 'and not due yet' do
          before { allow(job).to receive(:in_timeplan?).and_return(false) }

          it 'does not perform changes on matching tickets' do
            expect { job.run }.not_to change { matching_ticket.reload.state }
          end

          it 'does not update #last_run_at' do
            expect { job.run }.to not_change { job.reload.last_run_at }
          end

          it 'updates #next_run_at' do
            travel_to(Time.current.last_week) # force new value for #next_run_at

            expect { job.run }.to change { job.reload.next_run_at }
          end

          context 'but "force" flag is given' do
            it 'performs changes on matching tickets' do
              expect { job.run(true) }
                .to change { matching_ticket.reload.state }
                .and not_change { nonmatching_ticket.reload.state }
            end

            it 'updates #last_run_at' do
              expect { job.run(true) }.to change { job.reload.last_run_at }
            end

            it 'updates #next_run_at' do
              travel_to(Time.current.last_week) # force new value for #next_run_at

              expect { job.run }.to change { job.reload.next_run_at }
            end
          end
        end
      end

      context 'when job has pre_condition:current_user.id in selector' do
        let!(:matching_ticket) { create(:ticket, owner_id: 1) }
        let!(:nonmatching_ticket) { create(:ticket, owner_id: create(:agent).id) }

        let(:condition) do
          {
            'ticket.owner_id' => {
              'operator'         => 'is',
              'pre_condition'    => 'current_user.id',
              'value'            => '',
              'value_completion' => ''
            },
          }
        end

        before do
          UserInfo.current_user_id = create(:admin).id
          job
          UserInfo.current_user_id = nil
        end

        it 'performs changes on matching tickets' do
          expect { job.run(true) }
            .to change { matching_ticket.reload.state }
            .and not_change { nonmatching_ticket.reload.state }
        end

      end
    end

    describe '#executable?' do
      context 'for an inactive Job' do
        subject(:job) { create(:job, active: false) }

        it 'returns false' do
          expect(job.executable?).to be(false)
        end
      end

      context 'for an active job' do
        context 'updated in the last minute' do
          subject(:job) do
            create(:job, active:     true,
                         updated_at: 59.seconds.ago)
          end

          it 'returns false' do
            expect(job.executable?).to be(false)
          end
        end

        context 'updated over a minute ago' do
          context 'that has never run before' do
            subject(:job) do
              create(:job, active:     true,
                           updated_at: 60.seconds.ago)
            end

            it 'returns true' do
              expect(job.executable?).to be(true)
            end
          end

          context 'that was started in the last 10 minutes' do
            subject(:job) do
              create(:job, active:      true,
                           updated_at:  60.seconds.ago,
                           last_run_at: 9.minutes.ago)
            end

            it 'returns false' do
              expect(job.executable?).to be(false)
            end

            context '(or, given an argument, up to 10 minutes before that)' do
              subject(:job) do
                create(:job, active:      true,
                             updated_at:  60.seconds.ago,
                             last_run_at: 9.minutes.before(Time.current.yesterday))
              end

              it 'returns false' do
                expect(job.executable?(Time.current.yesterday)).to be(false)
              end
            end
          end

          context 'that was started over 10 minutes ago' do
            subject(:job) do
              create(:job, active:      true,
                           updated_at:  60.seconds.ago,
                           last_run_at: 10.minutes.ago)
            end

            it 'returns true' do
              expect(job.executable?).to be(true)
            end

            context '(or, given an argument, over 10 minutes before that)' do
              subject(:job) do
                create(:job, active:      true,
                             updated_at:  60.seconds.ago,
                             last_run_at: 10.minutes.before(Time.current.yesterday))
              end

              it 'returns true' do
                expect(job.executable?(Time.current.yesterday)).to be(true)
              end
            end

            context 'but is still running, up to 24 hours later' do
              subject(:job) do
                create(:job, active:      true,
                             updated_at:  60.seconds.ago,
                             running:     true,
                             last_run_at: 23.hours.ago)
              end

              it 'returns false' do
                expect(job.executable?).to be(false)
              end
            end

            context 'but is still running, over 24 hours later' do
              subject(:job) do
                create(:job, active:      true,
                             updated_at:  60.seconds.ago,
                             running:     true,
                             last_run_at: 24.hours.ago)
              end

              it 'returns true' do
                expect(job.executable?).to be(true)
              end
            end
          end
        end
      end
    end
  end

  describe 'Attributes:' do
    describe '#next_run_at' do
      subject(:job) { build(:job) }

      it 'is set automatically on save (cannot be set manually)' do
        job.next_run_at = 1.day.from_now

        expect { job.save }.to change(job, :next_run_at)
      end

      context 'for an inactive Job' do
        subject(:job) { build(:job, active: false) }

        it 'is nil' do
          expect { job.save }
            .not_to change(job, :next_run_at).from(nil)
        end
      end

      context 'for a never-on Job (all #timeplan values are false)' do
        subject(:job) { build(:job, :never_on) }

        it 'is nil' do
          expect { job.save }
            .not_to change(job, :next_run_at).from(nil)
        end
      end

      context 'when #timeplan contains at least one true value for :day, :hour, and :minute' do
        subject(:job) { build(:job, :never_on) }

        let(:base_time) { Time.current.beginning_of_week }

        # Tuesday & Thursday @ 12:00a, 12:30a, 6:00p, and 6:30p
        before do
          job.assign_attributes(
            timeplan: {
              days:    job.timeplan[:days].merge(Tue: true, Thu: true),
              hours:   job.timeplan[:hours].merge(0 => true, 18 => true),
              minutes: job.timeplan[:minutes].merge(0 => true, 30 => true),
            }
          )
        end

        let(:valid_timeslots) do
          [
            base_time + 1.day,                          # Tue 12:00a
            base_time + 1.day + 30.minutes,             # Tue 12:30a
            base_time + 1.day + 18.hours,               # Tue  6:00p
            base_time + 1.day + 18.hours + 30.minutes,  # Tue  6:30p
            base_time + 3.days,                         # Thu 12:00a
            base_time + 3.days + 30.minutes,            # Thu 12:30a
            base_time + 3.days + 18.hours,              # Thu  6:00p
            base_time + 3.days + 18.hours + 30.minutes, # Thu  6:30p
          ]
        end

        context 'for a Job that has never been run before' do
          context 'when record is saved at the start of the week' do
            before { travel_to(base_time) }

            it 'is set to the first valid timeslot of the week' do
              expect { job.save }
                .to change { job.next_run_at.to_i }  # comparing times is hard;
                .to(valid_timeslots.first.to_i)      # integers are less precise
            end
          end

          context 'when record is saved between two valid timeslots' do
            before { travel_to(valid_timeslots.third - 1.second) }

            it 'is set to the latter timeslot' do
              expect { job.save }
                .to change { job.next_run_at.to_i }  # comparing times is hard;
                .to(valid_timeslots.third.to_i)      # integers are less precise
            end
          end

          context 'when record is saved during a valid timeslot' do
            before { travel_to(valid_timeslots.fifth + 9.minutes + 59.seconds) }

            it 'is set to that timeslot' do
              expect { job.save }
                .to change { job.next_run_at.to_i }  # comparing times is hard;
                .to(valid_timeslots.fifth.to_i)      # integers are less precise
            end
          end
        end

        context 'for a Job that been run before' do
          context 'when record is saved in the same timeslot as #last_run_at' do
            before do
              job.assign_attributes(last_run_at: valid_timeslots.fourth + 5.minutes)
              travel_to(valid_timeslots.fourth + 7.minutes)
            end

            it 'is set to the next valid timeslot' do
              expect { job.save }
                .to change { job.next_run_at.to_i }  # comparing times is hard;
                .to(valid_timeslots.fifth.to_i)      # integers are less precise
            end
          end
        end
      end

      context 'when updating #next_run_at' do
        before do
          travel_to Time.zone.parse('2020-12-27 00:00')

          job.timeplan = { days: { Mon: true }, hours: { 0 => true }, minutes: { 0 => true } }
        end

        it 'sets #next_run_at time in selected time zone' do
          Setting.set 'timezone_default', 'Europe/Vilnius'

          expect { job.save }.to change(job, :next_run_at).to(Time.zone.parse('2020-12-27 22:00'))
        end

        it 'sets #next_run_at time in UTC' do
          expect { job.save }.to change(job, :next_run_at).to(Time.zone.parse('2020-12-28 00:00'))
        end
      end
    end

    describe '#perform' do
      describe 'Validations:' do
        describe '"article.note" key' do
          let(:perform) do
            { 'article.note' => { 'subject' => 'foo', 'internal' => 'true', 'body' => '' } }
          end

          it 'fails if an empty "body" is given' do
            expect { create(:job, perform: perform) }.to raise_error(ActiveRecord::RecordInvalid, %r{body is missing})
          end
        end

        describe '"notification.email" key' do
          let(:perform) do
            { 'notification.email' => { 'body' => 'foo', 'recipient' => '', 'subject' => 'bar' } }
          end

          it 'fails if an empty "recipient" is given' do
            expect { create(:job, perform: perform) }.to raise_error(ActiveRecord::RecordInvalid, %r{recipient is missing})
          end
        end

        describe '"notification.sms" key' do
          let(:perform) do
            { 'notification.sms' => { 'body' => 'foo', 'recipient' => '' } }
          end

          it 'fails if an empty "recipient" is given' do
            expect { create(:job, perform: perform) }.to raise_error(ActiveRecord::RecordInvalid, %r{recipient is missing})
          end
        end
      end
    end
  end

  # when running a very large job, tickets may change during the job
  # if tickets are fetched once, their action may be performed later on
  # when it no longer matches the conditions
  # https://github.com/zammad/zammad/issues/3329
  context 'job re-checks conditions' do
    let(:job)           { create(:job, condition: condition, perform: perform) }
    let(:ticket)        { create(:ticket, title: initial_title) }
    let(:initial_title) { 'initial 3329'  }
    let(:changed_title) { 'performed 3329' }

    let(:condition) do
      { 'ticket.title' => { 'value' => initial_title, 'operator' => 'is' } }
    end

    let(:perform) do
      { 'ticket.title' => { 'value'=> changed_title } }
    end

    it 'condition matches ticket' do
      ticket
      expect(job.send(:start_job, Time.zone.now, true)).to eq [ticket.id]
    end

    it 'action is performed' do
      ticket

      ticket_ids = job.send(:start_job, Time.zone.now, true)
      job.send(:run_slice, ticket_ids)

      expect(ticket.reload.title).to eq changed_title
    end

    it 'checks conditions' do
      ticket

      ticket_ids = job.send(:start_job, Time.zone.now, true)

      ticket.update! title: 'another title'

      job.send(:run_slice, ticket_ids)

      expect(ticket.reload.title).not_to eq changed_title
    end
  end

  describe 'Scheduler ignores "disable notifications == no" #3684', performs_jobs: true, sends_notification_emails: true do
    let!(:group) { create(:group) }
    let!(:agent)  { create(:agent, groups: [group]) }
    let!(:ticket) { create(:ticket, group: group, owner: agent) }
    let(:perform) do
      { 'article.note' => { 'body' => 'ccc', 'internal' => 'true', 'subject' => 'ccc' }, 'ticket.state_id' => { 'value' => 4 } }
    end

    context 'with disable_notification true' do
      let!(:notify_job) { create(:job, :always_on) }

      it 'does modify the ticket' do
        expect { notify_job.run(true) }.to change { ticket.reload.state }
      end

      it 'does not send a notification to the owner of the ticket' do
        check_notification do
          notify_job.run(true)
          perform_enqueued_jobs

          not_sent(
            template: 'ticket_update',
            user:     agent,
            objects:  hash_including({ article: nil })
          )
        end
      end
    end

    context 'with disable_notification false' do
      let!(:notify_job) { create(:job, :always_on, disable_notification: false, perform: perform) }

      it 'does modify the ticket' do
        expect { notify_job.run(true) }.to change { ticket.reload.state }
      end

      it 'does send a notification to the owner of the ticket with trigger note in notification body' do
        check_notification do
          notify_job.run(true)
          perform_enqueued_jobs

          sent(
            template: 'ticket_update',
            user:     agent,
            objects:  hash_including({ article: ticket.reload.articles.first })
          )
        end
      end
    end
  end
end
