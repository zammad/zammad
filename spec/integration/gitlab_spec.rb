# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
RSpec.describe GitLab, type: :integration do # rubocop:disable RSpec/FilePath

  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    required_envs = %w[GITLAB_ENDPOINT GITLAB_APITOKEN]
    required_envs.each do |key|
      skip("NOTICE: Missing environment variable #{key} for test! (Please fill up: #{required_envs.join(' && ')})") if ENV[key].blank?
    end
  end

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
end
