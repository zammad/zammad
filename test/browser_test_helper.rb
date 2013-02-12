ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'watir-webdriver'

class ActiveSupport::TestCase

  # Add more helper methods to be used by all tests here...
  def browser_login(data)
    all_tests = [
      {
        :name     => 'login',
        :instance => data[:instance] || Watir::Browser.new,
        :url      => data[:url] || 'http://localhost:3000',
        :action   => [
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'check',
            :element => :form,
            :id      => 'login',
            :result  => true,
          },
          {
            :execute => 'set',
            :element => :text_field,
            :name    => 'username',
            :value   => data[:username] || 'nicole.braun@zammad.org',
          },
          {
            :execute => 'set',
            :element => :text_field,
            :name    => 'password',
            :value   => data[:password] || 'test'
          },
          {
            :execute => 'click',
            :element => :button,
            :type    => 'submit',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute => 'check',
            :element => :form,
            :id      => 'login',
            :result  => false,
          },
        ],
      },
    ];
    return all_tests
  end

  def browser_signle_test_with_login(tests)
    all_tests = browser_login( {} )
    all_tests = all_tests.concat( tests )
    browser_single_test(all_tests)
  end

  def browser_double_test(tests)
    instance1 = browser_single_test( browser_login({
      :instance => tests[0][:instance1],
      :username => tests[0][:instance1_username],
      :password => tests[0][:instance1_password],
      :url      => tests[0][:url],
    }), true )
    instance2 = browser_single_test( browser_login({
      :instance => tests[0][:instance2],
      :username => tests[0][:instance2_username],
      :password => tests[0][:instance2_password],
      :url      => tests[0][:url],
    }), true )
    tests.each { |test|
      if test[:action]
        test[:action].each { |action|
          if action[:execute] == 'wait'
            sleep action[:value]
            next
          end
          next if !action[:where]
          if action[:where] == :instance1
            instance = instance1
          else
            instance = instance2
          end

          browser_element_action(test, action, instance)
        }
      end
    }
    instance1.close
    instance2.close
  end

  def browser_single_test(tests, keep_connection = false)
    instance = nil
    tests.each { |test|
      if test[:instance]
        instance = test[:instance]
      end
      if test[:url]
        instance.goto( test[:url] )
      end
      if test[:action]
        test[:action].each { |action|
          if action[:execute] == 'wait'
            sleep action[:value]
            next
          end
          browser_element_action(test, action, instance)
        }
      end
    }
    if keep_connection
      return instance
    end
    instance.close
  end
  
  def browser_element_action(test, action, instance)
    if action[:id]
      element = instance.send( action[:element], { :id => action[:id] } )
      if action[:result] == false
        assert( !element.exists?, "(#{test[:name]}) Element #{action[:element]} with id #{action[:id]} exists" )
      else
        assert( element.exists?, "(#{test[:name]}) Element #{action[:element]} with id #{action[:id]} doesn't exist" )
      end
    elsif action[:type]
      if action[:result] == false
        element = instance.send( action[:element], { :type => action[:type] } )
        assert( !element.exists?, "(#{test[:name]}) Element #{action[:element]} with type #{action[:type]} exists" )
      else
        element = instance.send( action[:element], { :type => action[:type] } )
        assert( element.exists?, "(#{test[:name]}) Element #{action[:element]} with type #{action[:type]} doesn't exist" )
      end
    elsif action[:name]
      if action[:result] == false
        element = instance.send( action[:element], { :name => action[:name] } )
        assert( !element.exists?, "(#{test[:name]}) Element #{action[:element]} with name #{action[:name]} exists" )
      else
        element = instance.send( action[:element], { :name => action[:name] } )
        assert( element.exists?, "(#{test[:name]}) Element #{action[:element]} with name #{action[:name]} doesn't exist" )
      end
    elsif action[:href]
      if action[:result] == false
        element = instance.send( action[:element], { :href => action[:href] } )
        assert( !element.exists?, "(#{test[:name]}) Element #{action[:element]} with href #{action[:href]} exists" )
      else
        element = instance.send( action[:element], { :href => action[:href] } )
        assert( element.exists?, "(#{test[:name]}) Element #{action[:element]} with href #{action[:href]} doesn't exist" )
      end
    elsif action[:element] == :url
        if instance.url =~ /#{Regexp.quote(action[:result])}/
          assert( true, "(#{test[:name]}) url #{instance.url} is matching #{action[:result]}" )
        else
          assert( false, "(#{test[:name]}) url #{instance.url} is not matching #{action[:result]}" )
        end
    else
      assert( false, "(#{test[:name]}) unknow selector for '#{action[:element]}'" )
    end
    if action[:execute] == 'set'
      element.set( action[:value] )
    elsif action[:execute] == 'click'
      element.click
    elsif action[:execute] == 'send_key'
      element.send_keys action[:value]
    elsif action[:execute] == 'match'
      if element.text =~ /#{Regexp.quote(action[:value])}/
        if action[:match_result]
          assert( true, "(#{test[:name]}) matching '#{action[:value]}' in content '#{element.text}'" )
        else
          assert( false, "(#{test[:name]}) matching '#{action[:value]}' in content '#{element.text}' but should not!" )
        end
      else
        if !action[:match_result]
          assert( true, "(#{test[:name]}) not matching '#{action[:value]}' in content '#{element.text}'" )
        else
          assert( false, "(#{test[:name]}) not matching '#{action[:value]}' in content '#{element.text}' but should not!" )
        end
      end
    elsif action[:execute] == 'check'
    else
      assert( false, "(#{test[:name]}) unknow action '#{action[:execute]}'" )
    end
  end
end
