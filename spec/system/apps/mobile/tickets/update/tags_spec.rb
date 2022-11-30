# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Ticket > Update > Tags', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, title: 'Ticket Title', group: group) }

  let(:tags_element) do
    find('label', text: 'Tags').sibling('.formkit-inner')
  end

  before do
    %w[tag1 other_tag].each { |elem| ticket.tag_add elem, 1 }

    visit "/tickets/#{ticket.id}/information"
  end

  it 'shows existing tags' do
    within tags_element do
      expect(page)
        .to have_text(%r{tag1}i)
        .and(have_text(%r{other_tag}i))
    end
  end

  it 'adds additional tag' do
    tags_element.click

    search_box = find(:fillable_field, placeholder: 'Tag name…')

    search_box.send_keys 'test'
    search_box.send_keys :enter

    find('button', text: 'test')

    click_on 'Done'

    wait_for_gql('shared/entities/tags/graphql/mutations/assignment/update.graphql')

    within tags_element do
      expect(page).to have_text(%r{test}i)
    end

    expect(ticket.reload.tag_list).to match_array %w[tag1 other_tag test]
  end

  it 'removes an existing tag' do
    tags_element.click

    click_on 'tag1'

    find('button[aria-checked="false"]', text: 'tag1')

    click_on 'Done'

    wait_for_gql('shared/entities/tags/graphql/mutations/assignment/update.graphql')

    within tags_element do
      expect(page)
        .to have_no_text(%r{tag1}i)
        .and have_text(%r{other_tag}i)
    end

    expect(ticket.reload.tag_list).to match_array %w[other_tag]
  end
end
