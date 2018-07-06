
require 'integration_test_helper'

class PackageTest < ActiveSupport::TestCase

  test 'packages' do
    tests = [

      # test 1 - normal install
      {
        zpm: '{
  "name": "UnitTestSample",
  "version": "1.0.1",
  "vendor": "Znuny GmbH",
  "license": "ABC",
  "url": "http://znuny.org/",
  "description": [
    {
      "language": "en",
      "text": "some description"
    }
  ],
  "files": [
    {
      "permission": "644",
      "location": "test.txt",
      "content": "YWJjw6TDtsO8w58="
    },
    {
      "permission": "644",
      "location": "some/dir/test.txt",
      "content": "YWJjw6TDtsO8w58="
    },
    {
      "permission": "644",
      "location": "db/addon/unit_test_sample/20121212000001_create_base.rb",
      "content": "Y2xhc3MgQ3JlYXRlQmFzZSA8IEFjdGl2ZVJlY29yZDo6TWlncmF0aW9uWzQuMl0NCiAgZGVmIHNlbGYudXANCiAgIGNyZWF0ZV90YWJsZSA6c2FtcGxlX3RhYmxlcyBkbyB8dHwNCiAgICAgIHQuY29sdW1uIDpuYW1lLCAgICAgICAgICAgOnN0cmluZywgOmxpbWl0ID0+IDE1MCwgIDpudWxsID0+IHRydWUNCiAgICAgIHQuY29sdW1uIDpkYXRhLCAgICAgICAgICAgOnN0cmluZywgOmxpbWl0ID0+IDUwMDAsIDpudWxsID0+IHRydWUNCiAgICBlbmQNCiAgZW5kDQoNCiAgZGVmIHNlbGYuZG93bg0KICAgIGRyb3BfdGFibGUgOnNhbXBsZV90YWJsZXMNCiAgZW5kDQplbmQ="
    }
  ]
}',
        action: 'install',
        result: true,
        verify: {
          package: {
            name: 'UnitTestSample',
            version: '1.0.1',
          },
          check_files: [
            {
              location: 'test.txt',
              result: true,
            },
            {
              location: 'test2.txt',
              result: false,
            },
            {
              location: 'some/dir/test.txt',
              result: true,
            },
          ],
        },
      },

      # test 2 - renstall
      {
        action: 'reinstall',
        name: 'UnitTestSample',
        result: true,
        verify: {
          package: {
            name: 'UnitTestSample',
            version: '1.0.1',
          },
          check_files: [
            {
              location: 'test.txt',
              result: true,
            },
            {
              location: 'test2.txt',
              result: false,
            },
            {
              location: 'some/dir/test.txt',
              result: true,
            },
          ],
        },
      },

      # test 3 - try to install same package again / should not work
      {
        zpm: '{
  "name": "UnitTestSample",
  "version": "1.0.1",
  "vendor": "Znuny GmbH",
  "license": "ABC",
  "url": "http://znuny.org/",
  "description": [
    {
      "language": "en",
      "text": "some description"
    }
  ],
  "files": [
    {
      "permission": "644",
      "location": "test.txt",
      "content": "YWJjw6TDtsO8w58="
    }
  ]
}',
        action: 'install',
        result: false,
      },

      # test 4 - try to install lower version / should not work
      {
        zpm: '{
  "name": "UnitTestSample",
  "version": "1.0.0",
  "vendor": "Znuny GmbH",
  "license": "ABC",
  "url": "http://znuny.org/",
  "description": [
    {
      "language": "en",
      "text": "some description"
    }
  ],
  "files": [
    {
      "permission": "644",
      "location": "test.txt",
      "content": "YWJjw6TDtsO8w58="
    }
  ]
}',
        action: 'install',
        result: false,
      },

      # test 5 - upgrade 7 should work
      {
        zpm: '{
  "name": "UnitTestSample",
  "version": "1.0.2",
  "vendor": "Znuny GmbH",
  "license": "ABC",
  "url": "http://znuny.org/",
  "description": [
    {
      "language": "en",
      "text": "some description"
    }
  ],
  "files": [
    {
      "permission": "644",
      "location": "test.txt2",
      "content": "YWJjw6TDtsO8w58="
    },
    {
      "permission": "644",
      "location": "some/dir/test.txt2",
      "content": "YWJjw6TDtsO8w58="
    },
    {
      "permission": "644",
      "location": "db/addon/unit_test_sample/20121212000001_create_base.rb",
      "content": "Y2xhc3MgQ3JlYXRlQmFzZSA8IEFjdGl2ZVJlY29yZDo6TWlncmF0aW9uWzQuMl0NCiAgZGVmIHNlbGYudXANCiAgIGNyZWF0ZV90YWJsZSA6c2FtcGxlX3RhYmxlcyBkbyB8dHwNCiAgICAgIHQuY29sdW1uIDpuYW1lLCAgICAgICAgICAgOnN0cmluZywgOmxpbWl0ID0+IDE1MCwgIDpudWxsID0+IHRydWUNCiAgICAgIHQuY29sdW1uIDpkYXRhLCAgICAgICAgICAgOnN0cmluZywgOmxpbWl0ID0+IDUwMDAsIDpudWxsID0+IHRydWUNCiAgICBlbmQNCiAgZW5kDQoNCiAgZGVmIHNlbGYuZG93bg0KICAgIGRyb3BfdGFibGUgOnNhbXBsZV90YWJsZXMNCiAgZW5kDQplbmQ="
    }
  ]
}',
        action: 'install',
        result: true,
        verify: {
          package: {
            name: 'UnitTestSample',
            version: '1.0.2',
          },
          check_files: [
            {
              location: 'test.txt2',
              result: true,
            },
            {
              location: 'test.txt',
              result: false,
            },
            {
              location: 'test2.txt',
              result: false,
            },
            {
              location: 'some/dir/test.txt2',
              result: true,
            },
          ],
        },
      },

      # test 6 - uninstall package / should work
      {
        name: 'UnitTestSample',
        version: '1.0.2',
        action: 'uninstall',
        result: true,
        verify: {
          check_files: [
            {
              location: 'test.txt',
              result: false,
            },
            {
              location: 'test2.txt',
              result: false,
            },
          ],
        },
      },

      # test 7 - check auto_install mechanism
      {
        zpm: '{
  "name": "UnitTestSample",
  "version": "1.0.2",
  "vendor": "Znuny GmbH",
  "license": "ABC",
  "url": "http://znuny.org/",
  "description": [
    {
      "language": "en",
      "text": "some description"
    }
  ],
  "files": [
    {
      "permission": "644",
      "location": "test.txt2",
      "content": "YWJjw6TDtsO8w58="
    },
    {
      "permission": "644",
      "location": "some/dir/test.txt2",
      "content": "YWJjw6TDtsO8w58="
    },
    {
      "permission": "644",
      "location": "db/addon/unit_test_sample/20121212000001_create_base.rb",
      "content": "Y2xhc3MgQ3JlYXRlQmFzZSA8IEFjdGl2ZVJlY29yZDo6TWlncmF0aW9uWzQuMl0NCiAgZGVmIHNlbGYudXANCiAgIGNyZWF0ZV90YWJsZSA6c2FtcGxlX3RhYmxlcyBkbyB8dHwNCiAgICAgIHQuY29sdW1uIDpuYW1lLCAgICAgICAgICAgOnN0cmluZywgOmxpbWl0ID0+IDE1MCwgIDpudWxsID0+IHRydWUNCiAgICAgIHQuY29sdW1uIDpkYXRhLCAgICAgICAgICAgOnN0cmluZywgOmxpbWl0ID0+IDUwMDAsIDpudWxsID0+IHRydWUNCiAgICBlbmQNCiAgZW5kDQoNCiAgZGVmIHNlbGYuZG93bg0KICAgIGRyb3BfdGFibGUgOnNhbXBsZV90YWJsZXMNCiAgZW5kDQplbmQ="
    }
  ]
}',
        action: 'auto_install',
        result: true,
        verify: {
          package: {
            name: 'UnitTestSample',
            version: '1.0.2',
          },
          check_files: [
            {
              location: 'test.txt2',
              result: true,
            },
            {
              location: 'test.txt',
              result: false,
            },
            {
              location: 'test2.txt',
              result: false,
            },
            {
              location: 'some/dir/test.txt2',
              result: true,
            },
          ],
        },
      },

      # test 8 - check uninstall / should work
      {
        name: 'UnitTestSample',
        version: '1.0.2',
        action: 'uninstall',
        result: true,
        verify: {
          check_files: [
            {
              location: 'test.txt',
              result: false,
            },
            {
              location: 'test2.txt',
              result: false,
            },
          ],
        },
      },

    ]
    tests.each do |test|
      if test[:action] == 'install'
        begin
          package = Package.install(string: test[:zpm])
        rescue => e
          puts 'ERROR: ' + e.inspect
        end
        if test[:result]
          assert(package, 'install package not successful')
          issues = package.verify
          assert(!issues, 'package verify not successful')
        else
          assert(!package, 'install package successful but should not')
        end
      elsif test[:action] == 'reinstall'
        begin
          package = Package.reinstall(test[:name])
        rescue
          package = false
        end
        if test[:result]
          assert(package, 'reinstall package not successful')
          issues = package.verify
          assert(!issues, 'package verify not successful')
        else
          assert(!package, 'reinstall package successful but should not')
        end
      elsif test[:action] == 'uninstall'
        if test[:zpm]
          begin
            package = Package.uninstall(string: test[:zpm])
          rescue
            package = false
          end
        else
          begin
            package = Package.uninstall(name: test[:name], version: test[:version])
          rescue
            package = false
          end
        end
        if test[:result]
          assert(package, 'uninstall package not successful')
        else
          assert(!package, 'uninstall package successful but should not')
        end
      elsif test[:action] == 'auto_install'
        if test[:zpm]
          if !File.exist?(Rails.root.to_s + '/auto_install/')
            Dir.mkdir(Rails.root.to_s + '/auto_install/', 0o755)
          end
          location = Rails.root.to_s + '/auto_install/unittest.zpm'
          file = File.new(location, 'wb')
          file.write(test[:zpm])
          file.close
        end
        begin
          success = Package.auto_install()
        rescue
          success = false
        end
        if test[:zpm]
          File.delete(location )
        end
      end
      if test[:verify] && test[:verify][:package]
        exists = Package.where(name: test[:verify][:package][:name], version: test[:verify][:package][:version]).first
        assert(exists, "package '#{test[:verify][:package][:name]}' is not installed" )
      end
      next if !test[:verify]
      next if !test[:verify][:check_files]

      test[:verify][:check_files].each do |item|
        exists = File.exist?(item[:location])
        if item[:result]
          assert(exists, "'#{item[:location]}' exists" )
        else
          assert(!exists, "'#{item[:location]}' doesn't exists" )
        end
      end
    end

  end
end
