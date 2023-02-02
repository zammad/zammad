# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

    wait_for_form_to_settle('form-ticket-edit')
  end

  it 'shows existing tags' do
    expect(find_autocomplete('Tags')).to have_selected_options([%r{tag1}i, %r{other_tag}i])
  end

  it 'adds additional tag' do
    tags = find_autocomplete('Tags')
    tags.search_for_option('test')

    wait_for_gql('shared/entities/tags/graphql/mutations/assignment/update.graphql')

    expect(tags).to have_selected_option(%r{test}i)
    expect(ticket.reload.tag_list).to match_array %w[tag1 other_tag test]
  end

  it 'removes an existing tag' do
    tags = find_autocomplete('Tags')

    # Despite the name of the action, the following DESELECTS the currently selected tag.
    #   This works because this value is already selected in the field.
    tags.select_option('tag1')

    wait_for_gql('shared/entities/tags/graphql/mutations/assignment/update.graphql')

    expect(tags).to have_no_selected_option(%r{tag1}i).and have_selected_option(%r{other_tag}i)
    expect(ticket.reload.tag_list).to match_array %w[other_tag]
  end
end
