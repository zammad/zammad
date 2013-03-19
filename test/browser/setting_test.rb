# encoding: utf-8
require 'browser_test_helper'

class SettingTest < TestCase
  def test_setting
    tests = [
      {
        :name     => 'setting',
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#settings"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#settings/security"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#settings/security/third_party_auth"]',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'check',
            :css     => '#auth_facebook select[name="auth_facebook"]',
            :result  => true,
          },

          # set yes
          {
            :execute => 'select',
            :css     => '#auth_facebook select[name="auth_facebook"]',
            :value   => 'yes',
          },
          {
            :execute => 'click',
            :css     => '#auth_facebook button[type=submit]',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute      => 'match',
            :css          => '#auth_facebook select[name="auth_facebook"]',
            :value        => 'yes',
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '#auth_facebook select[name="auth_facebook"]',
            :value        => 'no',
            :match_result => false,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },

          # set no
          {
            :execute => 'select',
            :css     => '#auth_facebook select[name="auth_facebook"]',
            :value   => 'no',
          },
          {
            :execute => 'click',
            :css     => '#auth_facebook button[type=submit]',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute      => 'match',
            :css          => '#auth_facebook select[name="auth_facebook"]',
            :value        => 'yes',
            :match_result => false,
          },
          {
            :execute      => 'match',
            :css          => '#auth_facebook select[name="auth_facebook"]',
            :value        => 'no',
            :match_result => true,
          },

          # set key and secret
          {
            :execute => 'set',
            :css     => '#auth_facebook_credentials input[name=app_id]',
            :value   => 'id_test1234äöüß',
          },
          {
            :execute => 'set',
            :css     => '#auth_facebook_credentials input[name=app_secret]',
            :value   => 'secret_test1234äöüß',
          },
          {
            :execute => 'click',
            :css     => '#auth_facebook_credentials button[type=submit]',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute      => 'match',
            :css          => '#auth_facebook_credentials input[name=app_id]',
            :value        => 'id_test1234äöüß',
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '#auth_facebook_credentials input[name=app_secret]',
            :value        => 'secret_test1234äöüß',
            :match_result => true,
          },

          # set key and secret again
          {
            :execute => 'set',
            :css     => '#auth_facebook_credentials input[name=app_id]',
            :value   => '---',
          },
          {
            :execute => 'set',
            :css     => '#auth_facebook_credentials input[name=app_secret]',
            :value   => '---',
          },
          {
            :execute => 'click',
            :css     => '#auth_facebook_credentials button[type=submit]',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute      => 'match',
            :css          => '#auth_facebook_credentials input[name=app_id]',
            :value        => '---',
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '#auth_facebook_credentials input[name=app_secret]',
            :value        => '---',
            :match_result => true,
          },

        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'master@example.com' })
  end
end
