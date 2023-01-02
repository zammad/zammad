# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Package, type: :model do

  # cleanup package files
  after :all do # rubocop:disable RSpec/BeforeAfterAll
    %w[example.rb app/controllers/test_controller.rb].each do |file|
      next if !Rails.root.join(file).exist?

      Rails.root.join(file).delete
    end
  end

  def get_package_structure(name, files, version = '1.0.1')
    <<-JSON
      {
        "name": "#{name}",
        "version": "#{version}",
        "vendor": "Zammad Foundation",
        "license": "ABC",
        "url": "https://zammad.org/",
        "description": [
          {
            "language": "en",
            "text": "some description"
          }
        ],
        "files": #{files}
      }
    JSON
  end

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

  let(:package_name)         { 'UnitTestSample' }
  let(:package_zpm_json)     { get_package_structure(package_name, package_zpm_files_json) }
  let(:old_package_zpm_json) { get_package_structure(package_name, package_zpm_files_json, '1.0.0') }
  let(:new_package_zpm_json) { get_package_structure(package_name, package_zpm_files_json, '1.0.2') }

  context 'when performing different package actions' do
    context 'when installing a package' do
      it 'does install package' do
        expect { described_class.install(string: package_zpm_json) }
          .to change(described_class, :count)
          .and change(Store, :count)
      end
    end

    context 'when reinstalling a package' do
      before do
        described_class.install(string: package_zpm_json)
      end

      it 'does not reinstall package' do
        expect { described_class.reinstall(package_name) }
          .to not_change(described_class, :count)
          .and not_change(Store, :count)
      end
    end

    context 'when installing a package again' do
      before do
        described_class.install(string: package_zpm_json)
      end

      it 'does not install package' do
        expect { described_class.install(string: package_zpm_json) }
          .to raise_error(RuntimeError)
          .and not_change(described_class, :count)
          .and not_change(Store, :count)
      end
    end

    context 'when installing a package with a lower version' do
      before do
        described_class.install(string: package_zpm_json)
      end

      it 'does not install package' do
        expect { described_class.install(string: old_package_zpm_json) }
          .to raise_error(RuntimeError)
          .and not_change(described_class, :count)
          .and not_change(Store, :count)
      end
    end

    context 'when upgrading a package' do
      before do
        described_class.install(string: package_zpm_json)
      end

      it 'does install package' do
        expect { described_class.install(string: new_package_zpm_json) }
          .to not_raise_error
          .and not_change(described_class, :count)
          .and change(Store, :count)
      end
    end

    context 'when installing + uninstalling a package' do
      before do
        described_class.install(string: package_zpm_json)
      end

      it 'does install + uninstall the package' do
        expect { described_class.uninstall(string: package_zpm_json) }
          .to not_raise_error
          .and change(described_class, :count)
          .and not_change(Store, :count)
      end
    end

    context 'when auto installing' do
      before do
        FileUtils.mkdir_p(Rails.root.join('auto_install'))

        location = Rails.root.join('auto_install/unittest.zpm')
        file = File.new(location, 'wb')
        file.write(package_zpm_json)
        file.close
      end

      after do
        Rails.root.join('auto_install/unittest.zpm').delete
      end

      it 'does install package' do
        expect { described_class.auto_install }
          .to change(described_class, :count)
          .and change(Store, :count)
      end
    end

    context 'when verify package install' do
      context 'when verify is ok' do
        it 'returns no verify issues' do
          package = described_class.install(string: package_zpm_json)

          expect(package.verify).to be_nil
        end
      end

      context 'when verify is not ok' do
        it 'returns verify issues' do
          package = described_class.install(string: package_zpm_json)
          Rails.root.join('example.rb').delete

          expect(package.verify).not_to be_nil
        end
      end
    end
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
          .and not_change(described_class, :count)
          .and not_change(Store, :count)
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
