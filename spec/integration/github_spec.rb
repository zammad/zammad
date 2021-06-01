# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
RSpec.describe GitHub, type: :integration do # rubocop:disable RSpec/FilePath

  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    required_envs = %w[GITHUB_ENDPOINT GITHUB_APITOKEN]
    required_envs.each do |key|
      skip("NOTICE: Missing environment variable #{key} for test! (Please fill up: #{required_envs.join(' && ')})") if ENV[key].blank?
    end
  end

  let(:instance) { described_class.new(ENV['GITHUB_ENDPOINT'], ENV['GITHUB_APITOKEN']) }
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
          color:      '#fef2c0',
          text_color: '#000000',
          title:      'feature backlog'
        },
        {
          color:      '#bfdadc',
          text_color: '#000000',
          title:      'integration'
        }
      ],
    }
  end
  let(:invalid_issue_url) { 'https://github.com/organization/repository/issues/42' }

  describe '#issues_by_urls' do
    let(:result) { instance.issues_by_urls([ issue_url ]) }

    context 'when issue exists' do
      let(:issue_url) { ENV['GITHUB_ISSUE_LINK'] }

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
