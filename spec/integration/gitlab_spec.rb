# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
# rubocop:disable RSpec/FilePath
RSpec.describe GitLab, integration: true, required_envs: %w[GITLAB_ENDPOINT GITLAB_APITOKEN] do
  # rubocop:enable RSpec/FilePath

  let(:instance) { described_class.new(ENV['GITLAB_ENDPOINT'], ENV['GITLAB_APITOKEN']) }
  let(:issue_data) do
    {
      id:         '1',
      title:      'Example issue',
      url:        ENV['GITLAB_ISSUE_LINK'],
      icon_state: 'open',
      milestone:  'important milestone',
      assignees:  ['zammad-robot'],
      labels:     [
        {
          color:      '#FF0000',
          text_color: '#FFFFFF',
          title:      'critical'
        },
        {
          color:      '#0033CC',
          text_color: '#FFFFFF',
          title:      'label1'
        },
        {
          color:      '#D1D100',
          text_color: '#FFFFFF',
          title:      'special'
        }
      ],
    }
  end
  let(:invalid_issue_url) { "https://#{URI.parse(ENV['GITLAB_ISSUE_LINK']).host}/group/project/-/issues/1" }

  describe '#issues_by_urls' do
    let(:result) { instance.issues_by_urls([ issue_url ]) }

    context 'when issue exists' do
      let(:issue_url) { ENV['GITLAB_ISSUE_LINK'] }

      it 'returns a result list' do
        expect(result.size).to eq(1)
      end

      it 'returns issue data in the result list' do
        expect(result[0]).to eq(issue_data)
      end
    end

    context 'when issue does not exists' do
      let(:issue_url) { invalid_issue_url }

      it 'returns no result' do
        expect(result.size).to eq(0)
      end
    end
  end

  describe '#issue_by_url' do

    let(:result) { instance.issue_by_url(issue_url) }

    context 'when issue exists' do
      let(:issue_url) { ENV['GITLAB_ISSUE_LINK'] }

      it 'returns issue data' do
        expect(result).to eq(issue_data)
      end
    end

    context 'when issue does not exists' do
      let(:issue_url) { invalid_issue_url }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '#variables' do
    describe 'Zammad ignores relative GitLab URLs #3830' do
      let(:endpoint)     { ENV['GITLAB_ENDPOINT'].sub('api/graphql', 'subfolder/api/graphql') }
      let(:instance)     { described_class.new(endpoint, ENV['GITLAB_APITOKEN']) }
      let(:issue_url)    { "https://#{URI.parse(ENV['GITLAB_ISSUE_LINK']).host}/subfolder/group/project/-/issues/1" }
      let(:linked_issue) { GitLab::LinkedIssue.new(instance.client) }

      it 'does remove the subfolder from the fullpath to get the issue correctly' do
        expect(linked_issue.send(:variables, issue_url)[:fullpath]).to eq('group/project')
      end
    end
  end
end
