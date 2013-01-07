# encoding: utf-8
require 'test_helper'
 
class PackageTest < ActiveSupport::TestCase
  test 'packages' do
    tests = [

      # test 1
      {
        :zpm => '<?xml version="1.0"?>
<zpm version="1.0">
  <name>UnitTestSample</name>
  <version>1.0.1</version>
  <vendor>Znuny GmbH</vendor>
  <url>http://znuny.org/</url>
  <license>ABC</license>
  <description lang="en">some description</description>
  <filelist>
    <file permission="644" location="test.txt">YWJjw6TDtsO8w58=</file>
    <file permission="644" location="some/dir/test.txt">YWJjw6TDtsO8w58=</file>
    <file permission="644" location="db/addon/unit_test_sample/20121212000001_create_base.rb">Y2xhc3MgQ3JlYXRlQmFzZSA8IEFjdGl2ZVJlY29yZDo6TWlncmF0aW9uDQogIGRlZiBzZWxmLnVw
DQogICBjcmVhdGVfdGFibGUgOnNhbXBsZV90YWJsZXMgZG8gfHR8DQogICAgICB0LmNvbHVtbiA6
bmFtZSwgICAgICAgICAgIDpzdHJpbmcsIDpsaW1pdCA9PiAxNTAsICA6bnVsbCA9PiB0cnVlDQog
ICAgICB0LmNvbHVtbiA6ZGF0YSwgICAgICAgICAgIDpzdHJpbmcsIDpsaW1pdCA9PiA1MDAwLCA6
bnVsbCA9PiB0cnVlDQogICAgZW5kDQogIGVuZA0KDQogIGRlZiBzZWxmLmRvd24NCiAgICBkcm9w
X3RhYmxlIDpzYW1wbGVfdGFibGVzDQogIGVuZA0KZW5k</file>
  </filelist>
</zpm>',
        :action => 'install',
        :result => true,
        :verify => {
          :package => {
            :name    => 'UnitTestSample',
            :version => '1.0.1',
          },
          :check_files => [
            {
              :location => 'test.txt',
              :result   => true,
            },
            {
              :location => 'test2.txt',
              :result   => false,
            },
            {
              :location => 'some/dir/test.txt',
              :result   => true,
            },
          ],
        },
      },

      # test 2
      {
        :zpm => '<?xml version="1.0"?>
<zpm version="1.0">
  <name>UnitTestSample</name>
  <version>1.0.1</version>
  <vendor>Znuny GmbH</vendor>
  <url>http://znuny.org/</url>
  <license>ABC</license>
  <description lang="en">some description</description>
  <filelist>
    <file permission="644" location="test.txt">YWJjw6TDtsO8w58=</file>
  </filelist>
</zpm>',
        :action => 'install',
        :result => false,
      },

      # test 3
      {
        :zpm => '<?xml version="1.0"?>
<zpm version="1.0">
  <name>UnitTestSample</name>
  <version>1.0.0</version>
  <vendor>Znuny GmbH</vendor>
  <url>http://znuny.org/</url>
  <license>ABC</license>
  <description lang="en">some description</description>
  <filelist>
    <file permission="644" location="test.txt">YWJjw6TDtsO8w58=</file>
  </filelist>
</zpm>',
        :action => 'install',
        :result => false,
      },

      # test 4
      {
        :zpm => '<?xml version="1.0"?>
<zpm version="1.0">
  <name>UnitTestSample</name>
  <version>1.0.2</version>
  <vendor>Znuny GmbH</vendor>
  <url>http://znuny.org/</url>
  <license>ABC</license>
  <description lang="en">some description</description>
  <filelist>
    <file permission="644" location="test.txt2">YWJjw6TDtsO8w58=</file>
    <file permission="644" location="some/dir/test.txt2">YWJjw6TDtsO8w58=</file>
    <file permission="644" location="db/addon/unit_test_sample/20121212000001_create_base.rb">Y2xhc3MgQ3JlYXRlQmFzZSA8IEFjdGl2ZVJlY29yZDo6TWlncmF0aW9uDQogIGRlZiBzZWxmLnVw
DQogICBjcmVhdGVfdGFibGUgOnNhbXBsZV90YWJsZXMgZG8gfHR8DQogICAgICB0LmNvbHVtbiA6
bmFtZSwgICAgICAgICAgIDpzdHJpbmcsIDpsaW1pdCA9PiAxNTAsICA6bnVsbCA9PiB0cnVlDQog
ICAgICB0LmNvbHVtbiA6ZGF0YSwgICAgICAgICAgIDpzdHJpbmcsIDpsaW1pdCA9PiA1MDAwLCA6
bnVsbCA9PiB0cnVlDQogICAgZW5kDQogIGVuZA0KDQogIGRlZiBzZWxmLmRvd24NCiAgICBkcm9w
X3RhYmxlIDpzYW1wbGVfdGFibGVzDQogIGVuZA0KZW5k</file>
  </filelist>
</zpm>',
        :action => 'install',
        :result => true,
        :verify => {
          :package => {
            :name    => 'UnitTestSample',
            :version => '1.0.2',
          },
          :check_files => [
            {
              :location => 'test.txt2',
              :result   => true,
            },
            {
              :location => 'test.txt',
              :result   => false,
            },
            {
              :location => 'test2.txt',
              :result   => false,
            },
            {
              :location => 'some/dir/test.txt2',
              :result   => true,
            },
          ],
        },
      },

      # test 4
      {
        :name     => 'UnitTestSample',
        :version  => '1.0.2',
        :action   => 'uninstall',
        :result   => true,
        :verify   => {
          :check_files => [
            {
              :location => 'test.txt',
              :result   => false,
            },
            {
              :location => 'test2.txt',
              :result   => false,
            },
          ],
        },
      },

      # test 5
      {
        :zpm => '<?xml version="1.0"?>
<zpm version="1.0">
  <name>UnitTestSample</name>
  <version>1.0.2</version>
  <vendor>Znuny GmbH</vendor>
  <url>http://znuny.org/</url>
  <license>ABC</license>
  <description lang="en">some description</description>
  <filelist>
    <file permission="644" location="test.txt2">YWJjw6TDtsO8w58=</file>
    <file permission="644" location="some/dir/test.txt2">YWJjw6TDtsO8w58=</file>
    <file permission="644" location="db/addon/unit_test_sample/20121212000001_create_base.rb">Y2xhc3MgQ3JlYXRlQmFzZSA8IEFjdGl2ZVJlY29yZDo6TWlncmF0aW9uDQogIGRlZiBzZWxmLnVw
DQogICBjcmVhdGVfdGFibGUgOnNhbXBsZV90YWJsZXMgZG8gfHR8DQogICAgICB0LmNvbHVtbiA6
bmFtZSwgICAgICAgICAgIDpzdHJpbmcsIDpsaW1pdCA9PiAxNTAsICA6bnVsbCA9PiB0cnVlDQog
ICAgICB0LmNvbHVtbiA6ZGF0YSwgICAgICAgICAgIDpzdHJpbmcsIDpsaW1pdCA9PiA1MDAwLCA6
bnVsbCA9PiB0cnVlDQogICAgZW5kDQogIGVuZA0KDQogIGRlZiBzZWxmLmRvd24NCiAgICBkcm9w
X3RhYmxlIDpzYW1wbGVfdGFibGVzDQogIGVuZA0KZW5k</file>
  </filelist>
</zpm>',
        :action => 'auto_install',
        :result => true,
        :verify => {
          :package => {
            :name    => 'UnitTestSample',
            :version => '1.0.2',
          },
          :check_files => [
            {
              :location => 'test.txt2',
              :result   => true,
            },
            {
              :location => 'test.txt',
              :result   => false,
            },
            {
              :location => 'test2.txt',
              :result   => false,
            },
            {
              :location => 'some/dir/test.txt2',
              :result   => true,
            },
          ],
        },
      },

      # test 6
      {
        :name     => 'UnitTestSample',
        :version  => '1.0.2',
        :action   => 'uninstall',
        :result   => true,
        :verify   => {
          :check_files => [
            {
              :location => 'test.txt',
              :result   => false,
            },
            {
              :location => 'test2.txt',
              :result   => false,
            },
          ],
        },
      },

    ]
    tests.each { |test|
      if test[:action] == 'install'
        begin
          success = Package.install( :string => test[:zpm] )
        rescue => e
          puts 'ERROR: ' + e.inspect
          success = false
        end
        if test[:result]
          assert( success, "install package not successful" )
        else
          assert( !success, "install package successful but should not" )
        end
      elsif test[:action] == 'uninstall'
        if test[:zpm]
          begin
            success = Package.uninstall( :string => test[:zpm] )
          rescue
            success = false
          end
        else
          begin
            success = Package.uninstall( :name => test[:name], :version => test[:version] )
          rescue
            success = false
          end
        end
        if test[:result]
          assert( success, "uninstall package not successful" )
        else
          assert( !success, "uninstall package successful but should not" )
        end
      elsif test[:action] == 'auto_install'
        if test[:zpm]
          if !File.exist?( Rails.root.to_s + '/auto_install/' )
            Dir.mkdir( Rails.root.to_s + '/auto_install/', 0755)
          end
          location = Rails.root.to_s + '/auto_install/unittest.zpm'
          file = File.new( location, 'wb' )
          file.write( test[:zpm] ) 
          file.close
        end
        begin
          success = Package.auto_install()
        rescue
          success = false
        end
        if test[:zpm]
          File.delete( location )
        end
      end
      if test[:verify] && test[:verify][:package]
        exists = Package.where( :name => test[:verify][:package][:name], :version => test[:verify][:package][:version] ).first
        assert( exists, "package '#{test[:verify][:package][:name]}' is not installed" )
      end
      if test[:verify] && test[:verify][:check_files]
        test[:verify][:check_files].each {|item|
          exists = File.exist?( item[:location] )
          if item[:result]
            assert( exists, "'#{item[:location]}' exists" )
          else
            assert( !exists, "'#{item[:location]}' doesn't exists" )
          end
        }
      end
    }

  end
end