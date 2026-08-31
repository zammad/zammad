# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Answer::VisibilitySchedule::Add do
  subject(:add_schedule) do
    described_class.with_current_user(user).execute(answer:, visibility:, scheduled_at:)
  end

  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)        { create(:user, roles: [editor_role]) }

  let(:answer) do
    create(:knowledge_base_answer, from, category:, translation_attributes: { title: 'Stored title', kb_locale: primary_locale })
  end

  # The answer of every example starts out in the state its context names, so each of them has a
  #   definite state to schedule a change away from.
  let(:from) { :draft }

  let(:visibility)   { :published }
  let(:scheduled_at) { 1.week.from_now.change(sec: 0) }

  before { answer }

  # Re-read rather than asked of the returned record: the state is derived by a state machine the
  #   record memoizes, so an instance that was around before the save could answer from it.
  def visibility_after_add
    add_schedule

    KnowledgeBase::Answer.find(answer.id).visibility
  end

  it 'stores the date the state is to be reached at' do
    expect(add_schedule.published_at).to be_within(1.second).of(scheduled_at)
  end

  # The whole point of a schedule: nothing about the answer changes until the date is reached.
  it 'leaves the answer in the state it is in' do
    expect(visibility_after_add).to eq(:draft)
  end

  it 'reports the change as scheduled' do
    expect(add_schedule.visibility_schedules)
      .to eq([{ visibility: :published, scheduled_at: scheduled_at }])
  end

  it 'leaves the rest of the answer alone' do
    expect(add_schedule.translations.sole.title).to eq('Stored title')
  end

  # Each state is reached at one date, so there is only ever one schedule per state - moving it is
  #   what a client saves after editing an entry.
  context 'when the same state is already scheduled' do
    let(:answer) do
      create(:knowledge_base_answer, category:, published_at: 1.week.from_now.change(sec: 0),
                                     translation_attributes: { kb_locale: primary_locale })
    end
    let(:scheduled_at) { 1.month.from_now.change(sec: 0) }

    it 'moves it to the new date' do
      expect(add_schedule.published_at).to be_within(1.second).of(scheduled_at)
    end
  end

  # Both dates are ahead, and they run in the order the states rank - so the answer goes internal
  #   first and public afterwards.
  context 'when another state is scheduled for later' do
    let(:answer) do
      create(:knowledge_base_answer, category:, published_at: 1.month.from_now.change(sec: 0),
                                     translation_attributes: { kb_locale: primary_locale })
    end
    let(:visibility) { :internal }

    it 'keeps both schedules', :aggregate_failures do
      expect(add_schedule.visibility_schedules.pluck(:visibility)).to eq(%i[internal published])
      expect(visibility_after_add).to eq(:draft)
    end
  end

  # A state that is in effect can still be scheduled to be *left* - as long as the target ranks
  #   above it, which is the only direction the derived state can move in.
  context 'when the answer is published' do
    let(:from)       { :published }
    let(:visibility) { :archived }

    it 'schedules the archival', :aggregate_failures do
      expect(add_schedule.archived_at).to be_within(1.second).of(scheduled_at)
      expect(visibility_after_add).to eq(:published)
    end
  end

  # Otherwise the answer would leave the state right now, which is the update mutation's business,
  #   and it would do so as a schedule the client goes on showing.
  context 'with a date that has passed' do
    let(:scheduled_at) { 1.week.ago }

    it 'refuses it, naming the date' do
      expect { add_schedule }
        .to raise_error(an_instance_of(Exceptions::InvalidAttribute)
          .and(having_attributes(attribute: 'scheduledAt',
                                 message:   'A visibility change can only be scheduled for a point in time in the future.')))
        .and(not_change { answer.reload.published_at })
    end
  end

  # The date the answer reached that state at is what it would overwrite - silently taking the
  #   answer back out of a state it is in rather than scheduling anything.
  context 'when the state has already been reached' do
    let(:from)       { :published }
    let(:visibility) { :published }

    # On the state, not the date: no date makes this one schedulable again.
    it 'refuses it, naming the state' do
      expect { add_schedule }
        .to raise_error(an_instance_of(Exceptions::InvalidAttribute)
          .and(having_attributes(attribute: 'visibility',
                                 message:   'The answer has already reached this visibility state, so a change to it cannot be scheduled.')))
        .and(not_change { answer.reload.published_at })
    end

    # The same date, reached earlier: an archived answer has been published, and rescheduling that
    #   publication would only un-archive it now.
    context 'when a higher-ranked state is in effect' do
      let(:answer) do
        create(:knowledge_base_answer, :published, :archived, category:,
                                                              translation_attributes: { kb_locale: primary_locale })
      end

      it 'refuses it' do
        expect { add_schedule }.to raise_error(Exceptions::InvalidAttribute)
      end
    end
  end

  # The state is derived from the highest-ranked date that has passed, so a change only ever takes
  #   effect if the dates run in the same order as the states rank. CanBePublished validates that
  #   too, but each of its validations reports on the date it compares *from* - which is the entry
  #   the editor did not touch. The service says the same thing about the submitted date instead.
  describe 'a schedule that could never take effect' do
    let(:message) { 'Visibility changes take effect in the order internal, published, archived, and can only be scheduled in that order.' }

    context 'when a higher-ranked state is scheduled before it' do
      let(:answer) do
        create(:knowledge_base_answer, category:, archived_at: 1.week.from_now.change(sec: 0),
                                       translation_attributes: { kb_locale: primary_locale })
      end
      let(:scheduled_at) { 1.month.from_now.change(sec: 0) }

      it 'refuses it, naming the date the editor picked' do
        expect { add_schedule }
          .to raise_error(an_instance_of(Exceptions::InvalidAttribute)
            .and(having_attributes(attribute: 'scheduledAt', message: message)))
          .and(not_change { answer.reload.published_at })
      end
    end

    context 'when a lower-ranked state is scheduled after it' do
      let(:answer) do
        create(:knowledge_base_answer, category:, published_at: 1.week.from_now.change(sec: 0),
                                       translation_attributes: { kb_locale: primary_locale })
      end
      let(:visibility)   { :internal }
      let(:scheduled_at) { 1.month.from_now.change(sec: 0) }

      it 'refuses it, naming the date the editor picked' do
        expect { add_schedule }
          .to raise_error(an_instance_of(Exceptions::InvalidAttribute)
            .and(having_attributes(attribute: 'scheduledAt', message: message)))
          .and(not_change { answer.reload.internal_at })
      end
    end

    # An answer that is published without ever having been internal: going internal later would not
    #   take effect, so the same ordering validation refuses it.
    context 'when the state is outranked by one that is already in effect' do
      let(:from)       { :published }
      let(:visibility) { :internal }

      it 'refuses it' do
        expect { add_schedule }.to raise_error(Exceptions::InvalidAttribute, message)
      end
    end
  end

  # `draft` is what no date at all means, so there is nothing to schedule for it. The schema rules
  #   it out, which makes reaching the service with it a programming error.
  context 'with a state that stores no date' do
    let(:visibility) { :draft }

    it 'is a programming error' do
      expect { add_schedule }.to raise_error(KeyError)
    end
  end

  # Editor access to the answer is not asked by the service - the mutation's `answer_id` argument
  #   gates it, and its spec covers that. Writing knowledge base content at all is this one's own
  #   rule.
  context 'when the knowledge base is inactive' do
    before { knowledge_base.update!(active: false) }

    it 'refuses it' do
      expect { add_schedule }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
