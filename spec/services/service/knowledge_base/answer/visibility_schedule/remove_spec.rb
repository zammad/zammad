# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Answer::VisibilitySchedule::Remove do
  subject(:remove_schedule) do
    described_class.with_current_user(user).execute(answer:, visibility:)
  end

  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)        { create(:user, roles: [editor_role]) }

  let(:scheduled)  { 1.week.from_now.change(sec: 0) }
  let(:visibility) { :published }

  let(:answer) do
    create(:knowledge_base_answer, category:, published_at: scheduled,
                                   translation_attributes: { title: 'Stored title', kb_locale: primary_locale })
  end

  before { answer }

  # Re-read rather than asked of the returned record: the state is derived by a state machine the
  #   record memoizes, so an instance that was around before the save could answer from it.
  def visibility_after_remove
    remove_schedule

    KnowledgeBase::Answer.find(answer.id).visibility
  end

  it 'clears the date the state was to be reached at' do
    expect(remove_schedule.published_at).to be_nil
  end

  it 'reports nothing as scheduled any more' do
    expect(remove_schedule.visibility_schedules).to be_empty
  end

  # The change simply never happens - it was not in effect, so nothing about the answer changes.
  it 'leaves the answer in the state it is in' do
    expect(visibility_after_remove).to eq(:draft)
  end

  it 'leaves the rest of the answer alone' do
    expect(remove_schedule.translations.sole.title).to eq('Stored title')
  end

  context 'when another state is scheduled as well' do
    let(:answer) do
      create(:knowledge_base_answer, category:, internal_at: 1.day.from_now.change(sec: 0), published_at: scheduled,
                                     translation_attributes: { kb_locale: primary_locale })
    end

    it 'leaves that one alone' do
      expect(remove_schedule.visibility_schedules.pluck(:visibility)).to eq([:internal])
    end
  end

  # The wanted end state is reached either way, and the client removes an entry it is showing - one
  #   that somebody else removed, or that was reached in the meantime, is nothing to report back.
  context 'when the state is not scheduled' do
    let(:visibility) { :archived }

    it 'does nothing', :aggregate_failures do
      expect { remove_schedule }.not_to change { answer.reload.attributes }

      expect(remove_schedule).to eq(answer)
    end
  end

  # Clearing that date would take the answer out of a state it is *in*, which is the update
  #   mutation's business - a schedule is only ever a date still ahead. Passed over just as quietly,
  #   but the date has to survive it.
  context 'when the state has already been reached' do
    let(:answer) do
      create(:knowledge_base_answer, :published, category:, translation_attributes: { kb_locale: primary_locale })
    end

    it 'keeps the date the state was reached at' do
      expect { remove_schedule }.not_to change { answer.reload.published_at }
    end

    it 'leaves the answer published' do
      expect(visibility_after_remove).to eq(:published)
    end
  end

  # `draft` is what no date at all means, so there is nothing scheduled to clear for it. The schema
  #   rules it out, which makes reaching the service with it a programming error.
  context 'with a state that stores no date' do
    let(:visibility) { :draft }

    it 'is a programming error' do
      expect { remove_schedule }.to raise_error(KeyError)
    end
  end

  # Editor access to the answer is not asked by the service - the mutation's `answer_id` argument
  #   gates it, and its spec covers that. Writing knowledge base content at all is this one's own
  #   rule.
  context 'when the knowledge base is inactive' do
    before { knowledge_base.update!(active: false) }

    it 'refuses it' do
      expect { remove_schedule }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
