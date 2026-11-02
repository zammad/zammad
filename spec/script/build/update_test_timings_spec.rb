# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require Rails.root.join('script/build/update_test_timings.rb').to_s

RSpec.describe UpdateTestTimings do
  describe '.median' do
    it 'returns the middle value of an odd number of values' do
      expect(described_class.median([3.0, 1.0, 2.0])).to eq(2.0)
    end

    it 'returns the mean of the two middle values of an even number of values' do
      expect(described_class.median([4.0, 1.0, 3.0, 2.0])).to eq(2.5)
    end

    it 'returns the only value' do
      expect(described_class.median([7.0])).to eq(7.0)
    end
  end

  describe '#median_timings' do
    subject(:median_timings) { described_class.new(pipelines.keys).median_timings(%r{^rspec \d+/\d+$}) }

    let(:project_url) { "#{described_class::API_URL}/projects/#{described_class::PROJECT}" }

    # Pipeline id => job name => runtime per spec file, as printed in the job log.
    let(:pipelines) { {} }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('GITLAB_TOKEN').and_return('token')
      allow($stdout).to receive(:puts)

      job_id = 0

      pipelines.each do |pipeline_id, jobs|
        job_list = jobs.map do |name, timings|
          job_id += 1
          stub_job_log(job_id, timings)

          { 'id' => job_id, 'name' => name }
        end

        stub_request(:get, "#{project_url}/pipelines/#{pipeline_id}/jobs?per_page=100&page=1").to_return(body: job_list.to_json)
        stub_request(:get, "#{project_url}/pipelines/#{pipeline_id}/jobs?per_page=100&page=2").to_return(body: '[]')
      end
    end

    def stub_job_log(job_id, timings)
      log = timings.map { |path, seconds| "2026-10-30T20:16:44.494785Z 01O #{path}: #{seconds}\n" }.join

      stub_request(:get, "#{project_url}/jobs/#{job_id}/artifacts/trace").to_return(body: "Running specs\n#{log}Job succeeded\n")
    end

    context 'with a single pipeline' do
      let(:pipelines) do
        { '1' => { 'rspec 1/2' => { 'spec/a_spec.rb' => 12.3 }, 'rspec 2/2' => { 'spec/b_spec.rb' => 4.5 } } }
      end

      it 'returns the runtimes of that pipeline' do
        expect(median_timings).to eq('spec/a_spec.rb' => 12.3, 'spec/b_spec.rb' => 4.5)
      end
    end

    context 'with several pipelines' do
      let(:pipelines) do
        {
          '1' => { 'rspec 1/1' => { 'spec/a_spec.rb' => 71.0, 'spec/b_spec.rb' => 2.0 } },
          '2' => { 'rspec 1/1' => { 'spec/a_spec.rb' => 455.1, 'spec/b_spec.rb' => 4.0 } },
          '3' => { 'rspec 1/1' => { 'spec/a_spec.rb' => 430.2 } },
        }
      end

      it 'returns the median runtime of each file over the pipelines which measured it' do
        expect(median_timings).to eq('spec/a_spec.rb' => 430.2, 'spec/b_spec.rb' => 3.0)
      end
    end

    context 'when a file ran in more than one job of a pipeline' do
      let(:pipelines) do
        {
          '1' => { 'rspec 1/2' => { 'spec/a_spec.rb' => 9.0 }, 'rspec 2/2' => { 'spec/a_spec.rb' => 5.0 } },
          '2' => { 'rspec 1/1' => { 'spec/a_spec.rb' => 1.0 } },
          '3' => { 'rspec 1/1' => { 'spec/a_spec.rb' => 8.0 } },
        }
      end

      it 'uses its longest runtime in that pipeline' do
        expect(median_timings).to eq('spec/a_spec.rb' => 8.0)
      end
    end

    context 'with jobs which do not provide these timings' do
      let(:pipelines) do
        { '1' => { 'rspec 1/1' => { 'spec/a_spec.rb' => 1.0 }, 'capybara:chromium 1/1' => { 'spec/system/b_spec.rb' => 9.0 } } }
      end

      it 'ignores their runtimes' do
        expect(median_timings).to eq('spec/a_spec.rb' => 1.0)
      end
    end
  end
end
