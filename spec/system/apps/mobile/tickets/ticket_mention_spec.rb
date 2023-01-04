# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Ticket > Mentions', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)  { Group.find_by(name: 'Users') }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, group: group) }

  def visit_information
    visit "/tickets/#{ticket.id}/information"
    wait_for_gql 'apps/mobile/pages/ticket/graphql/queries/ticket.graphql'
  end

  it 'can subscribe to a ticket inside a dialog' do
    visit_information

    expect(find_toggle('Get notified')).to be_toggled_off
    expect(Mention.subscribed?(ticket, agent)).to be false

    find_button('Show ticket actions').click
    find_button('Subscribe').click

    wait_for_gql 'shared/entities/ticket/graphql/mutations/subscribe.graphql'

    expect(page).to have_button('Unsubscribe')

    click_on 'Done'

    expect(find_toggle('Get notified')).to be_toggled_on
    expect(Mention.subscribed?(ticket, agent)).to be true
  end

  it 'can unsubscribe from a ticket inside a dialog', current_user_id: 1 do
    Mention.subscribe!(ticket, agent)

    visit_information

    expect(find_toggle('Get notified')).to be_toggled_on

    find_button('Show ticket actions').click
    find_button('Unsubscribe').click

    wait_for_gql 'shared/entities/ticket/graphql/mutations/unsubscribe.graphql'

    expect(page).to have_button('Subscribe')
    expect(Mention.subscribed?(ticket, agent)).to be false
  end

  it 'can subscribe to a ticket in information page' do
    visit_information

    subscribe_field = find_toggle('Get notified')

    expect(subscribe_field).to be_toggled_off

    subscribe_field.toggle_on

    wait_for_gql 'shared/entities/ticket/graphql/mutations/subscribe.graphql'

    expect(subscribe_field).to be_toggled_on
    expect(Mention.subscribed?(ticket, agent)).to be true

    # don't see myself in a list of subscribers

    find_button('Show ticket actions').click
    expect(page).to have_button('Unsubscribe')
  end

  it 'can unsubscribe from a ticket in information page', current_user_id: 1 do
    Mention.subscribe!(ticket, agent)

    visit_information

    subscribe_field = find_toggle('Get notified')

    expect(subscribe_field).to be_toggled_on

    subscribe_field.toggle_off

    wait_for_gql 'shared/entities/ticket/graphql/mutations/unsubscribe.graphql'

    expect(subscribe_field).to be_toggled_off
    expect(Mention.subscribed?(ticket, agent)).to be false
  end

  it 'shows list of subscribers and can load all subscribers', current_user_id: 1 do
    agents = create_list(:agent, 10, groups: [group])
    agents.each { |agent| Mention.subscribe!(ticket, agent) }

    visit_information

    5.times { |i| expect(page).to have_text(agents[i].fullname) }

    expect(page).to have_no_text(agents[5].fullname)

    expect(page).to have_button('Show 5 more')

    find_button('Show 5 more').click

    (5..9).each { |i| expect(page).to have_text(agents[i].fullname) }
  end
end
