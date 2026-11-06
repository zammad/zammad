# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::ExternalReferences::List do
  let(:github_link) { 'https://github.com/example/example/issues/1' }
  let(:gitlab_link) { 'https://gitlab.example.com/example/example/-/issues/2' }
  let(:ticket) do
    create(:ticket, preferences: {
             github: { issue_links: [github_link] },
             gitlab: { issue_links: [gitlab_link] },
             idoit:  { object_ids: %w[42 43] },
           })
  end

  def references
    described_class.execute(ticket:)
  end

  it 'names nothing while no integration is on' do
    expect(references).to be_nil
  end

  it 'names only the references of the integrations that are on' do
    Setting.set('gitlab_integration', true)

    expect(references).to eq(gitlab: [gitlab_link])
  end

  context 'with every integration on' do
    before do
      %w[github_integration gitlab_integration idoit_integration].each { |name| Setting.set(name, true) }
    end

    it 'names the issue links and the i-doit objects by their IDs' do
      expect(references).to eq(github: [github_link], gitlab: [gitlab_link], idoit: [42, 43])
    end

    it 'leaves out an integration the ticket has no references of' do
      ticket.update!(preferences: { idoit: { object_ids: ['42'] } })

      expect(references).to eq(idoit: [42])
    end
  end
end
