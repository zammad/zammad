# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::ApplicationBuildChecksum, authenticated_as: false, type: :graphql do

  context 'when checking the application build checksum' do
    let(:vite_path) { Rails.public_path.join('vite') }
    let(:filename)  { "#{vite_path}/manifest.json" }
    let!(:initial_checksum) do
      # Create some content to the file at the beginning, because normally it not exists for the graphql tests.
      if !File.exist? filename
        Dir.mkdir(vite_path, 0o755)
        File.open(filename, 'a') do |file|
          file.write('{}')
        end
      end
      Digest::MD5.hexdigest(File.read(filename))
    end
    let(:query) do
      <<~QUERY
        query applicationBuildChecksum {
          applicationBuildChecksum
        }
      QUERY
    end

    before do
      File.open(filename, 'a') do |file|
        file.write("\n")
      end

      gql.execute(query)
    end

    after do
      if Digest::MD5.hexdigest('{}') == initial_checksum
        FileUtils.rm_rf vite_path
      end
    end

    it 'returns the checksum of the manifest file' do
      expect(gql.result.data).to not_eq(initial_checksum)
    end
  end
end
