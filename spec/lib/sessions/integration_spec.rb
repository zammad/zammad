# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Sessions integration with BackgroundServices::Service::ProcessSessionsJobs' do # rubocop:disable RSpec/DescribeClass
  # These examples spin up the real BackgroundServices::Service::ProcessSessionsJobs
  # worker on a separate thread and rely on real wall-clock time passing for it to pick
  # up and clean up sessions, so `sleep` calls interacting with the worker thread are
  # kept as real sleeps instead of `travel`.
  describe 'processing session client threads' do
    before do
      # The session store persists across examples/processes, so stale
      # queued messages from earlier runs would otherwise leak into these
      # client_id-keyed message queue assertions.
      Sessions.cleanup
      UserInfo.current_user_id = 1
    end

    context 'with websocket and ajax sessions for different users' do
      let(:roles)  { Role.where(name: ['Agent']) }
      let(:groups) { Group.all }

      # Created eagerly (let!, not let) and in this order: each creation
      # broadcasts a client notification to every currently connected
      # session, so agents must all exist before the first Sessions.create
      # below, or later agents' creation messages would leak into earlier
      # clients' message queues.
      let!(:agent1) do
        User.create_or_update(
          login:     'session-agent-1',
          firstname: 'Session',
          lastname:  'Agent 1',
          email:     'session-agent1@example.com',
          password:  'agentpw',
          active:    true,
          roles:     roles,
          groups:    groups,
        ).tap(&:save!)
      end

      let!(:agent2) do
        User.create_or_update(
          login:     'session-agent-2',
          firstname: 'Session',
          lastname:  'Agent 2',
          email:     'session-agent2@example.com',
          password:  'agentpw',
          active:    true,
          roles:     roles,
          groups:    groups,
        ).tap(&:save!)
      end

      let!(:agent3) do
        User.create_or_update(
          login:     'session-agent-3',
          firstname: 'Session',
          lastname:  'Agent 3',
          email:     'session-agent3@example.com',
          password:  'agentpw',
          active:    true,
          roles:     roles,
          groups:    groups,
        ).tap(&:save!)
      end

      it 'delivers messages to connected clients and stops their threads once sessions go idle', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        client_id1 = 'a1234'
        client_id2 = 'a123456'
        client_id3 = 'aabc'
        Sessions.destroy(client_id1)
        Sessions.destroy(client_id2)
        Sessions.destroy(client_id3)
        Sessions.create(client_id1, agent1.attributes, { type: 'websocket' })
        Sessions.create(client_id2, agent2.attributes, { type: 'ajax' })
        Sessions.create(client_id3, agent3.attributes, { type: 'ajax' })

        expect(Sessions.session_exists?(client_id1)).to be(true)
        expect(Sessions.session_exists?(client_id2)).to be(true)
        expect(Sessions.session_exists?(client_id3)).to be(true)

        # check if session still exists after idle cleanup
        travel 1.second
        Sessions.destroy_idle_sessions(3)
        expect(Sessions.session_exists?(client_id1)).to be(true)
        expect(Sessions.session_exists?(client_id2)).to be(true)
        expect(Sessions.session_exists?(client_id3)).to be(true)

        # check if session still exists after idle cleanup with touched sessions
        travel 4.seconds
        Sessions.touch(client_id1)
        Sessions.touch(client_id2)
        Sessions.touch(client_id3)
        Sessions.destroy_idle_sessions(3)
        expect(Sessions.session_exists?(client_id1)).to be(true)
        expect(Sessions.session_exists?(client_id2)).to be(true)
        expect(Sessions.session_exists?(client_id3)).to be(true)

        # check session data
        data = Sessions.get(client_id1)
        expect(data[:meta]).to be_present
        expect(data[:user]).to be_present
        expect(data[:user]['id']).to eq(agent1.id)

        data = Sessions.get(client_id2)
        expect(data[:meta]).to be_present
        expect(data[:user]).to be_present
        expect(data[:user]['id']).to eq(agent2.id)

        data = Sessions.get(client_id3)
        expect(data[:meta]).to be_present
        expect(data[:user]).to be_present
        expect(data[:user]['id']).to eq(agent3.id)

        # send data to one client
        Sessions.send(client_id1, { msg: 'äöüß123' })
        Sessions.send(client_id1, { msg: 'äöüß1234' })
        messages = Sessions.queue(client_id1)
        expect(messages.count).to eq(3)
        expect(messages[0]['event']).to eq('ws:login')
        expect(messages[0]['data']['success']).to be(true)
        expect(messages[1]['msg']).to eq('äöüß123')
        expect(messages[2]['msg']).to eq('äöüß1234')

        messages = Sessions.queue(client_id2)
        expect(messages.count).to eq(1)
        expect(messages[0]['event']).to eq('ws:login')
        expect(messages[0]['data']['success']).to be(true)

        messages = Sessions.queue(client_id3)
        expect(messages.count).to eq(1)
        expect(messages[0]['event']).to eq('ws:login')
        expect(messages[0]['data']['success']).to be(true)

        # broadcast to all clients
        Sessions.broadcast({ msg: 'ooo123123123123123123' })
        messages = Sessions.queue(client_id1)
        expect(messages.count).to eq(1)
        expect(messages[0]['msg']).to eq('ooo123123123123123123')

        messages = Sessions.queue(client_id2)
        expect(messages.count).to eq(1)
        expect(messages[0]['msg']).to eq('ooo123123123123123123')

        messages = Sessions.queue(client_id3)
        expect(messages.count).to eq(1)
        expect(messages[0]['msg']).to eq('ooo123123123123123123')

        # send dedicated message to user
        Sessions.send_to(agent1.id, { msg: 'ooo1231231231231231234' })
        messages = Sessions.queue(client_id1)
        expect(messages.count).to eq(1)
        expect(messages[0]['msg']).to eq('ooo1231231231231231234')

        messages = Sessions.queue(client_id2)
        expect(messages.count).to eq(0)

        messages = Sessions.queue(client_id3)
        expect(messages.count).to eq(0)

        worker = nil

        # start jobs
        jobs = Thread.new do
          worker = BackgroundServices::Service::ProcessSessionsJobs.new(manager: nil)
          worker.launch
        end
        sleep 6

        # check client threads
        expect(worker.client_threads.key?(client_id1)).to be(true)
        expect(worker.client_threads.key?(client_id2)).to be(true)
        expect(worker.client_threads.key?(client_id3)).to be(true)

        # check if session still exists after idle cleanup
        travel 10.seconds
        Sessions.destroy_idle_sessions(2)
        travel 2.seconds

        # check client sessions
        expect(Sessions.session_exists?(client_id1)).to be(false)
        expect(Sessions.session_exists?(client_id2)).to be(false)
        expect(Sessions.session_exists?(client_id3)).to be(false)

        sleep 6

        # check client threads
        expect(worker.client_threads.key?(client_id1)).to be(false)
        expect(worker.client_threads.key?(client_id2)).to be(false)
        expect(worker.client_threads.key?(client_id3)).to be(false)

        # exit jobs
        jobs.exit
        jobs.join
      end
    end

    context 'with several sessions for the same and different users created over time' do
      let(:roles)        { Role.where(name: ['Agent']) }
      let(:groups)       { Group.all }
      let(:organization) do
        Organization.create(
          name:          "SomeOrg::#{SecureRandom.uuid}", active: true,
          updated_by_id: 1,
          created_by_id: 1,
        )
      end

      let(:agent1) do
        User.create_or_update(
          login:        'session-agent-1',
          firstname:    'Session',
          lastname:     'Agent 1',
          email:        'session-agent1@example.com',
          password:     'agentpw',
          active:       true,
          organization: organization,
          roles:        roles,
          groups:       groups,
        ).tap(&:save!)
      end

      let(:agent2) do
        User.create_or_update(
          login:        'session-agent-2',
          firstname:    'Session',
          lastname:     'Agent 2',
          email:        'session-agent2@example.com',
          password:     'agentpw',
          active:       true,
          organization: organization,
          roles:        roles,
          groups:       groups,
        ).tap(&:save!)
      end

      let(:agent3) do
        User.create_or_update(
          login:        'session-agent-3',
          firstname:    'Session',
          lastname:     'Agent 3',
          email:        'session-agent3@example.com',
          password:     'agentpw',
          active:       true,
          organization: organization,
          roles:        roles,
          groups:       groups,
        ).tap(&:save!)
      end

      it 'destroys idle sessions once they have gone idle', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        client_id1_0 = 'b1234-1'
        client_id1_1 = 'b1234-2'
        client_id2   = 'b123456'
        client_id3   = 'c123456'
        Sessions.destroy(client_id1_0)
        Sessions.destroy(client_id1_1)
        Sessions.destroy(client_id2)
        Sessions.destroy(client_id3)

        worker = nil

        # start jobs
        jobs = Thread.new do
          worker = BackgroundServices::Service::ProcessSessionsJobs.new(manager: nil)
          worker.launch
        end
        sleep 5
        Sessions.create(client_id1_0, agent1.attributes, { type: 'websocket' })
        sleep 6.5
        Sessions.create(client_id1_1, agent1.attributes, { type: 'websocket' })
        sleep 3.2
        Sessions.create(client_id2, agent2.attributes, { type: 'ajax' })
        sleep 3.2
        Sessions.create(client_id3, agent3.attributes, { type: 'websocket' })

        expect(Sessions.session_exists?(client_id1_0)).to be(true)
        expect(Sessions.session_exists?(client_id1_1)).to be(true)
        expect(Sessions.session_exists?(client_id2)).to be(true)
        expect(Sessions.session_exists?(client_id3)).to be(true)

        # check if session still exists after idle cleanup
        travel 10.seconds
        Sessions.destroy_idle_sessions(2)
        travel 2.seconds

        # check client sessions
        expect(Sessions.session_exists?(client_id1_0)).to be(false)
        expect(Sessions.session_exists?(client_id1_1)).to be(false)
        expect(Sessions.session_exists?(client_id2)).to be(false)
        expect(Sessions.session_exists?(client_id3)).to be(false)

        # exit jobs
        jobs.exit
        jobs.join
      end
    end
  end
end
