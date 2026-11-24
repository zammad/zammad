# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::SetTicketReferences, :aggregate_failures do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:token)  { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let(:ticket) { create(:ticket, group:) }

  let(:issue)       { 'https://github.com/example/app/issues/12' }
  let(:other_issue) { 'https://github.com/example/app/issues/7' }
  let(:projector)   { { 'id' => 4711, 'title' => 'Projector Hall 3' } }

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
    Setting.set('github_integration', true)
    Setting.set('idoit_integration', true)

    allow(Service::Ticket::ExternalReferences::IssueTracker::Item).to receive(:execute) do |type:, issue_link:|
      { url: issue_link } if type == 'github' && [issue, other_issue].include?(issue_link)
    end
    allow(Idoit).to receive(:query).and_return({ 'result' => [] })
  end

  def call(arguments, user: agent, token: self.token)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments: { ticket_number: ticket.number }.merge(arguments), user:, token:).to_h
  end

  # An error comes as its code and message.
  def text(result)
    body = result[:content].first[:text]
    return body if !result[:isError]

    JSON.parse(body).values_at('error', 'message').join(': ')
  end

  def objects_with(filter, *objects)
    allow(Idoit).to receive(:query).with('cmdb.objects', filter).and_return({ 'result' => objects })
  end

  it 'is offered over MCP only while an integration is switched on, as a destructive write that reaches other systems' do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).not_to include(described_class)

    annotations = Service::MCPServer::ToolDefinition.execute(tool: described_class, user: agent, token:).annotations
    expect(annotations.to_h).to eq(readOnlyHint: false, destructiveHint: true, idempotentHint: true, openWorldHint: true)

    Setting.set('github_integration', false)
    Setting.set('idoit_integration', false)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).not_to include(described_class)
  end

  it 'adds and removes GitHub issues, as the token\'s user, and leaves the others' do
    ticket.update!(preferences: { github: { issue_links: [other_issue, 'https://github.com/example/app/issues/3'] } })

    result = call({ add: [{ system: 'github', value: "#{issue}/" }], remove: [{ system: 'github', value: "#{other_issue}/" }] })

    expect(result[:isError]).to be(false)
    expect(ticket.reload.preferences.dig('github', 'issue_links')).to eq(['https://github.com/example/app/issues/3', issue])
    expect(ticket.updated_by).to eq(agent)
    expect(result[:structuredContent]).to eq(
      'ticket_id' => ticket.id, 'ticket_number' => ticket.number, 'url' => "https://support.example.com/#ticket/zoom/#{ticket.id}",
      'added' => [{ 'system' => 'github', 'value' => issue }], 'removed' => [{ 'system' => 'github', 'value' => other_issue }],
      'already_present' => [], 'not_present' => [], 'refused' => [],
      'references' => { 'github' => ['https://github.com/example/app/issues/3', issue] }
    )
    expect(output_schema_errors(described_class.tool_output_schema, result[:structuredContent])).to be_empty
    expect(text(result)).to include("Added: GitHub issue #{issue}.", "Removed: GitHub issue #{other_issue}.", 'References now: GitHub issue https://github.com/example/app/issues/3, ')
  end

  it 'names what the ticket had already or did not have, and changes nothing for it' do
    ticket.update!(preferences: { github: { issue_links: [issue] } })

    result = call({ add: [{ system: 'github', value: issue }], remove: [{ system: 'github', value: other_issue }] })

    expect(result[:structuredContent]).to include('already_present' => [{ 'system' => 'github', 'value' => issue }], 'not_present' => [{ 'system' => 'github', 'value' => other_issue }])
    expect(text(result)).to include("Already linked: GitHub issue #{issue}.", "Not linked, so not removed: GitHub issue #{other_issue}.")
  end

  it 'saves what its system finds and names what it refuses, and fails where it saves nothing' do
    missing = 'https://github.com/example/app/issues/404'
    allow(Service::Ticket::ExternalReferences::IssueTracker::Item).to receive(:execute).with(type: 'github', issue_link: 'nonsense')
      .and_raise(Exceptions::UnprocessableContent, 'Invalid GitHub issue link format')

    result = call({ add: [{ system: 'github', value: issue }, { system: 'github', value: missing }, { system: 'github', value: 'nonsense' }] })

    expect(result[:isError]).to be(false)
    expect(ticket.reload.preferences.dig('github', 'issue_links')).to eq([issue])
    expect(result[:structuredContent]['refused']).to eq([
                                                          { 'system' => 'github', 'value' => missing, 'reason' => 'GitHub has no issue at this link, or the integration\'s token may not read it.' },
                                                          { 'system' => 'github', 'value' => 'nonsense', 'reason' => 'Invalid GitHub issue link format. Give the link of an issue, as GitHub shows it.' },
                                                        ])
    expect(text(result)).to include("Not added: GitHub issue #{missing}: GitHub has no issue at this link")

    expect(text(call({ add: [{ system: 'github', value: missing }] }))).to start_with('not_found: ')
  end

  it 'counts a link the ticket holds in another spelling as present, and fails where only that and a refusal remain' do
    ticket.update!(preferences: { github: { issue_links: ["#{issue.upcase.sub('HTTPS://', 'https://')}/"] } })

    result = call({ add: [{ system: 'github', value: issue }, { system: 'github', value: 'https://github.com/example/app/issues/404' }] })

    expect(text(result)).to start_with('not_found: ').and include("Already linked: GitHub issue #{issue.upcase.sub('HTTPS://', 'https://')}/.")
    expect(ticket.reload.preferences.dig('github', 'issue_links')).to eq(["#{issue.upcase.sub('HTTPS://', 'https://')}/"])
  end

  it 'says so where the system does not answer, without changing the ticket' do
    allow(Service::Ticket::ExternalReferences::IssueTracker::Item).to receive(:execute).and_raise(RuntimeError, 'GitHub request failed.')

    result = call({ add: [{ system: 'github', value: issue }] })

    expect(text(result)).to start_with('unavailable: ').and include('GitHub did not answer. Tell the user that GitHub cannot be reached right now.')
    expect(ticket.reload.preferences['github']).to be_nil
  end

  it 'adds and removes GitLab issues, as GitLab finds them' do
    Setting.set('gitlab_integration', true)
    gitlab_issue = 'https://git.example.com/group/app/-/issues/5'
    ticket.update!(preferences: { gitlab: { issue_links: ['https://git.example.com/group/app/-/issues/1'] } })
    allow(Service::Ticket::ExternalReferences::IssueTracker::Item).to receive(:execute).with(type: 'gitlab', issue_link: gitlab_issue).and_return({ url: gitlab_issue })

    result = call({ add: [{ system: 'gitlab', value: gitlab_issue }], remove: [{ system: 'gitlab', value: 'https://git.example.com/group/app/-/issues/1' }] })

    expect(ticket.reload.preferences.dig('gitlab', 'issue_links')).to eq([gitlab_issue])
    expect(text(result)).to include("Added: GitLab issue #{gitlab_issue}.", 'Removed: GitLab issue https://git.example.com/group/app/-/issues/1.')
  end

  it 'takes at most ten references to add and ten to remove' do
    references = Array.new(11) { |index| { system: 'github', value: "https://github.com/example/app/issues/#{index + 1}" } }

    expect(text(call({ add: references }))).to include('Name at most 10 references to add and 10 to remove.')
  end

  it 'refuses a system that is switched off, an unknown one and an empty value, naming what can be used' do
    expect(text(call({ add: [{ system: 'gitlab', value: issue }] }))).to include('GitLab is not switched on in Zammad. References can be set to: GitHub, i-doit.')
    expect(text(call({ add: [{ system: 'jira', value: issue }] }))).to include('system "jira" is none of github, gitlab, idoit.')
    expect(text(call({ remove: [{ system: 'idoit', value: ' ' }] }))).to include('A reference to i-doit has no value.')
    expect(text(call({}))).to include('Name at least one reference to add or to remove.')
  end

  context 'with i-doit' do
    it 'adds and removes an object by its ID, as i-doit shows it' do
      objects_with({ ids: [4711] }, projector)
      ticket.update!(preferences: { idoit: { object_ids: ['815'] } })

      result = call({ add: [{ system: 'idoit', value: '4711' }], remove: [{ system: 'idoit', value: '815' }] })

      expect(result[:structuredContent]).to include('added' => [{ 'system' => 'idoit', 'value' => 4711 }], 'removed' => [{ 'system' => 'idoit', 'value' => 815 }])
      expect(ticket.reload.preferences.dig('idoit', 'object_ids')).to eq([4711])
      expect(text(result)).to include('Added: i-doit object 4711.', 'References now: i-doit object 4711.')
    end

    it 'refuses an object named otherwise than by its ID, to add or to remove, and one i-doit does not have' do
      ticket.update!(preferences: { idoit: { object_ids: [4711] } })

      expect(text(call({ add: [{ system: 'idoit', value: 'Projector Hall 3' }] }))).to include('Name an i-doit object by its ID, as i-doit shows it.')
      expect(text(call({ remove: [{ system: 'idoit', value: 'Projector Hall 3' }] }))).to include('Name an i-doit object by its ID, as i-doit shows it.')
      expect(text(call({ add: [{ system: 'idoit', value: '99' }] }))).to include('i-doit has no object with the ID 99.')
      expect(Idoit).not_to have_received(:query).with('cmdb.objects', hash_including(:title))
      expect(ticket.reload.preferences.dig('idoit', 'object_ids')).to eq([4711])
    end

    it 'says so where i-doit does not answer' do
      allow(Idoit).to receive(:query).and_raise(RuntimeError, "Can't fetch objects from https://cmdb.example.com: timeout")

      expect(text(call({ add: [{ system: 'idoit', value: '4711' }] }))).to start_with('unavailable: ').and include('i-doit did not answer.')
    end
  end

  it 'saves nothing where the ticket moved to a group the user may not change while its systems were asked' do
    readable = create(:group)
    hidden   = create(:group)
    agent.group_ids_access_map = { group.id => 'full', readable.id => 'read' }
    lookup = proc do |group_id|
      proc do |issue_link:, **|
        ticket.update_columns(group_id:)
        { url: issue_link }
      end
    end

    allow(Service::Ticket::ExternalReferences::IssueTracker::Item).to receive(:execute, &lookup.call(readable.id))
    expect(text(call({ add: [{ system: 'github', value: issue }] }))).to start_with('read_only: ')

    ticket.update_columns(group_id: group.id)
    allow(Service::Ticket::ExternalReferences::IssueTracker::Item).to receive(:execute, &lookup.call(hidden.id))
    expect(text(call({ add: [{ system: 'github', value: issue }] }))).to start_with('not_found: ')

    expect(ticket.reload.preferences['github']).to be_nil
  end

  it 'changes no ticket the user may only read' do
    agent.group_names_access_map = { group.name => 'read' }

    expect(text(call({ add: [{ system: 'github', value: issue }] }))).to include('read_only')
    expect(ticket.reload.preferences['github']).to be_nil
  end
end
