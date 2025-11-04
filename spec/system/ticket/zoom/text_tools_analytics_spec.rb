# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Zoom > Text Tools Analytics', authenticated_as: :authenticate, type: :system do
  let(:group)            { Group.first }
  let(:agent)            { create(:agent, groups: [group]) }
  let(:ticket)           { create(:ticket, group:) }
  let(:ai_analytics_run) { create(:ai_analytics_run) }
  let(:reply_body)       { Faker::Lorem.unique.paragraph }

  let(:ai_service_text_tool_result) do
    Struct.new(:content, :stored_result, :ai_analytics_run, :fresh, keyword_init: true).new(
      content:          Faker::Lorem.unique.paragraph,
      stored_result:    nil,
      ai_analytics_run:,
      fresh:            false,
    )
  end

  def authenticate
    skip('Bubble menu does not work when using Chrome.') if Capybara.current_driver == :zammad_chrome

    allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

    setup_ai_provider
    Setting.set('ai_assistance_text_tools', true)
    Setting.set('ui_richtext_bubble_menu', true)

    AI::TextTool.destroy_all
    create(:ai_text_tool, name: 'Dummy', instruction: 'Make it nice.')

    ai_service_spy = instance_spy(Service::AIAssistance::TextTools)
    allow(Service::AIAssistance::TextTools).to receive(:new).and_return(ai_service_spy)
    allow(ai_service_spy).to receive(:execute).and_return(ai_service_text_tool_result)

    agent
  end

  before do |example|
    visit "ticket/zoom/#{ticket.id}"

    find(:richtext).send_keys(reply_body)

    # Wait for the taskbar update to finish.
    taskbar_timestamp = Taskbar.last.updated_at
    wait.until { Taskbar.last.updated_at != taskbar_timestamp }

    find(:richtext).send_keys([magic_key, 'a'])

    trigger_text_tools_modal if !example.metadata[:do_not_trigger_text_tools_modal]
  end

  def trigger_text_tools_modal
    find("[aria-label='Writing Assistant Tools']").click
    find('.js-action', text: 'Dummy').click

    modal_ready
  end

  it 'records usage implicitly', do_not_trigger_text_tools_modal: true do
    expect(ai_analytics_run.usages.find_by(user: agent)).to be_nil

    trigger_text_tools_modal

    expect(ai_analytics_run.usages.find_by(user: agent)).to have_attributes(
      rating: nil,
    )
  end

  it 'records positive feedback when giving thumbs up' do
    in_modal do
      click '.js-aiPositiveReaction'

      expect(page).to have_no_text('Any feedback on this result?')
        .and have_text('Thank you for your feedback.')
        .and have_no_css('.js-aiFeedbackButtons')
        .and have_css('.js-aiRegenerate')
        .and have_no_css('.js-aiCommentField')
    end

    expect(ai_analytics_run.usages.find_by(user: agent)).to have_attributes(
      rating: true,
    )
  end

  it 'records negative feedback when giving thumbs down (w/ optional comment)' do
    in_modal do
      expect(page).to have_text('Any feedback on this result?')
        .and have_no_text('Thank you for your feedback.')

      click '.js-aiNegativeReaction'

      expect(page).to have_no_text('Any feedback on this result?')
        .and have_field('comment', placeholder: 'Thanks for the feedback. Please explain what went wrong?')
        .and have_no_css('.js-aiFeedbackToolbar')
    end

    expect(ai_analytics_run.usages.find_by(user: agent)).to have_attributes(
      rating: false,
    )

    in_modal do
      fill_in 'comment', with: 'bad bot'
      click_on 'Submit Comment'

      expect(page).to have_text('Thank you for your feedback.')
        .and have_no_css('.js-aiCommentField')
        .and have_css('.js-aiRegenerate')
    end

    expect(ai_analytics_run.usages.find_by(user: agent)).to have_attributes(
      rating:  false,
      comment: 'bad bot',
    )
  end

  it 'records approval when accepting the result' do
    in_modal do
      click_on 'Approve'
    end

    expect(ai_analytics_run.usages.find_by(user: agent)).to have_attributes(
      context: {
        'approved' => true,
      },
    )
  end
end
