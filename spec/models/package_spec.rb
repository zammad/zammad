# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Package, type: :model do
  let(:package_zpm_files_json) do
    <<-JSON
      [
        {
          "permission": "644",
          "location": "example.rb",
          "content": "YWJjw6TDtsO8w58="
        },
        {
          "permission": "644",
          "location": "app/controllers/test_controller.rb",
          "content": "YWJjw6TDtsO8w58="
        }
      ]
    JSON
  end
  let(:package_zpm_json) do
    <<-JSON
    {
      "name": "UnitTestSample",
      "version": "1.0.1",
      "vendor": "Zammad Foundation",
      "license": "ABC",
      "url": "https://zammad.org/",
      "description": [
        {
          "language": "en",
          "text": "some description"
        }
      ],
      "files": #{package_zpm_files_json}
    }
    JSON
  end

  context 'with different file locations' do
    context 'with correct file locations' do
      it 'installation should work' do
        expect(described_class.install(string: package_zpm_json)).to be_truthy
      end
    end

    shared_examples 'check not allowed file location' do |file_location|
      let(:package_zpm_files_json) do
        <<-JSON
          [
            {
              "permission": "644",
              "location": "example.rb",
              "content": "YWJjw6TDtsO8w58="
            },
            {
              "permission": "644",
              "location": "#{file_location}",
              "content": "YWJjw6TDtsO8w58="
            }
          ]
        JSON
      end

      it 'installation should raise a error and package/store should not be present, because of not allowed file location' do
        expect { described_class.install(string: package_zpm_json) }
          .to raise_error(RuntimeError)
          .and change(described_class, :count).by(0)
          .and change(Store, :count).by(0)
      end
    end

    context "with not allowed file location part: '..'" do
      include_examples 'check not allowed file location', '../../../../../tmp/test_controller.rb'
    end

    context "with not allowed file location part: '%2e%2e'" do
      include_examples 'check not allowed file location', '%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/tmp/test_controller.rb'
    end
  end
end
