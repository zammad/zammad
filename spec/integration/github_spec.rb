# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'integration/git_integration_base_examples'

RSpec.describe GitHub, integration: true, required_envs: %w[GITHUB_ENDPOINT GITHUB_ISSUE_LINK GITHUB_APITOKEN] do
  let(:invalid_issue_url) { 'https://github.com/organization/repository/issues/42' }
  let(:issue_data) do
    {
      id:         '1575',
      title:      'GitHub integration',
      url:        ENV['GITHUB_ISSUE_LINK'],
      icon_state: 'closed',
      milestone:  '4.0',
      assignees:  ['Thorsten'],
      labels:     [
        {
          color:      '#84b6eb',
          text_color: '#000000',
          title:      'enhancement'
        },
        {
          color:      '#bfdadc',
          text_color: '#000000',
          title:      'integration'
        }
      ],
    }
  end
  let(:instance) { described_class.new(endpoint: ENV['GITHUB_ENDPOINT'], api_token: ENV['GITHUB_APITOKEN']) }

  it_behaves_like 'Git Integration Base', issue_type: :github

  describe '#issues_by_urls' do
    let(:result) { instance.issues_by_urls([ issue_url ]) }

    context 'when issue exists' do
      let(:issue_url) { ENV['GITHUB_ISSUE_LINK'] }

      it 'returns a issues list' do
        expect(result[:issues].size).to eq(1)
      end

      it 'returns issue data in the issues list' do
        expect(result[:issues][0]).to eq(issue_data)
      end

      it 'returns no url replacements' do
        expect(result[:url_replacements].size).to eq(0)
      end
    end

    context 'when issue does not exists' do
      let(:issue_url) { invalid_issue_url }

      it 'returns no issues' do
        expect(result[:issues].size).to eq(0)
      end

      it 'returns no url replacements' do
        expect(result[:url_replacements].size).to eq(0)
      end
    end
  end

  describe '#issue_by_url' do

    let(:result) { instance.issue_by_url(issue_url) }

    context 'when issue exists' do
      let(:issue_url) { ENV['GITHUB_ISSUE_LINK'] }

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
end
