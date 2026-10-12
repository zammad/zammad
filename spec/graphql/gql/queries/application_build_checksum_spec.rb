# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::ApplicationBuildChecksum, authenticated_as: false, type: :graphql do

  context 'when checking the application build checksum' do
    let(:public_path)      { Pathname.new(Dir.mktmpdir) }
    let(:manifest_content) { '{"some":"manifest"}' }
    let(:query) do
      <<~QUERY
        query applicationBuildChecksum {
          applicationBuildChecksum
        }
      QUERY
    end

    before do
      manifest = public_path.join('assets/frontend/vite/.vite/manifest.json')
      FileUtils.mkdir_p(manifest.dirname)
      File.write(manifest, manifest_content)

      allow(Rails).to receive(:public_path).and_return(public_path)

      gql.execute(query)
    end

    after do
      FileUtils.rm_rf(public_path)
    end

    it 'returns the checksum of the manifest file' do
      expect(gql.result.data).to eq(Digest::MD5.hexdigest(manifest_content))
    end
  end
end
