# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

  describe 'Multiple uninstalling packages will course missing backup files #4577' do
    let(:core_file) { Rails.root.join('app/models/ticket.rb') }
    let(:orig_content) { File.read(core_file) }

    let(:package_zpm_files_json) do
      <<-JSON
        [
          {
            "permission": "644",
            "location": "app/models/ticket.rb",
            "content": "YWJjw6TDtsO8w58="
          }
        ]
      JSON
    end

    before do
      orig_content
    end

    def expect_install_package
      described_class.install(string: package_zpm_json)
      expect(File.exist?(core_file)).to be(true)
      expect(File.read(core_file)).to eq('abcäöüß')
      expect(File.exist?("#{core_file}.save")).to be(true)
      expect(File.read("#{core_file}.save")).to eq(orig_content)
      expect(described_class.last.state).to eq('installed')
    end

    def expect_uninstall_package_files
      described_class.uninstall(string: package_zpm_json, migration_not_down: true, reinstall: true)
      expect(File.exist?(core_file)).to be(true)
      expect(File.read(core_file)).to eq(orig_content)
      expect(File.exist?("#{core_file}.save")).to be(false)
      expect(described_class.last.state).to eq('uninstalled')
    end

    def expect_reinstall_package
      described_class.reinstall(package_name)
      expect(File.exist?(core_file)).to be(true)
      expect(File.read(core_file)).to eq('abcäöüß')
      expect(File.exist?("#{core_file}.save")).to be(true)
      expect(File.read("#{core_file}.save")).to eq(orig_content)
      expect(described_class.last.state).to eq('installed')
    end

    def expect_uninstall_package
      described_class.uninstall(string: package_zpm_json)
      expect(File.exist?(core_file)).to be(true)
      expect(File.read(core_file)).to eq(orig_content)
      expect(File.exist?("#{core_file}.save")).to be(false)
      expect(File.read(core_file)).to eq(orig_content)
    end

    it 'does support the classic package migration path but with multiple uninstalls' do
      expect_install_package
      expect_uninstall_package_files
      expect_uninstall_package_files
      expect_reinstall_package
      expect_uninstall_package
    end

    it 'does have a proper package state after multiple reinstalls' do
      expect_install_package
      expect_reinstall_package
      expect_reinstall_package
      expect_uninstall_package
    end
  end

  describe 'Vendor url in installed package is the zammad instance url #4753' do
    it 'does have a url for the package' do
      described_class.install(string: package_zpm_json)
      expect(described_class.last.url).to eq('https://zammad.org/')
    end
  end

  describe 'Package: Missing backup files for files with the same content #5012' do
    let(:package_v1_files) do
      <<-JSON
        [
          {
            "permission": "644",
            "location": "lib/version.rb",
            "content": "#{Base64.strict_encode64(File.read('lib/version.rb')).strip}"
          }
        ]
      JSON
    end
    let(:package_v2_files) do
      <<-JSON
        []
      JSON
    end

    let(:package_v1) { get_package_structure(package_name, package_v1_files, '1.0.0') }
    let(:package_v2) { get_package_structure(package_name, package_v2_files, '1.0.1') }

    it 'does not lose core files when patched by package and released in future updates of zammad' do
      described_class.install(string: package_v1)
      described_class.install(string: package_v2)
      expect(File.exist?('lib/version.rb')).to be(true)
    end
  end

  describe 'Package: File conflict with packages which include the same file location #5014' do
    let(:package_1) { get_package_structure('PackageA', package_zpm_files_json, '1.0.0') }
    let(:package_2) { get_package_structure('PackageB', package_zpm_files_json, '1.0.0') }

    it 'does not allow to patch the same file twice via package' do
      described_class.install(string: package_1)
      expect { described_class.install(string: package_2) }.to raise_error("Can't create file, because file 'example.rb' is already provided by package 'PackageA'!")
    end
  end
end
