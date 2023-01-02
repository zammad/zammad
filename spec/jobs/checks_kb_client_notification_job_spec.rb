# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ChecksKbClientNotificationJob, performs_jobs: true, type: :job do
  include_context 'basic Knowledge Base'

  describe 'pushes to users who have access' do
    let(:admin)    { create(:admin) }
    let(:agent)    { create(:agent) }
    let(:customer) { create(:customer) }

    before do
      allow_any_instance_of(described_class)
        .to receive(:active_users)
        .and_return([admin, agent, customer])

      allow(PushMessages).to receive(:send_to)

      described_class.perform_now 'KnowledgeBase::Answer', answer.id
    end

    shared_examples 'message pushed to given users' do |prefix, **args|
      context "when answer is #{prefix}" do
        let(:answer) { send("#{prefix}_answer") }

        args.each do |key, value|
          it "#{key} #{value ? 'is' : 'not'} notified" do
            expect(PushMessages).send(value ? :to : :not_to, have_received(:send_to).with(send(key).id, any_args))
          end
        end
      end
    end

    include_examples 'message pushed to given users', 'published', admin: true, agent: true,  customer: false
    include_examples 'message pushed to given users', 'internal',  admin: true, agent: true,  customer: false
    include_examples 'message pushed to given users', 'draft',     admin: true, agent: false, customer: false
    include_examples 'message pushed to given users', 'archived',  admin: true, agent: false, customer: false
  end
end
