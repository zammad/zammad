# encoding: utf-8
require 'browser_test_helper'

class AgentTicketActionLevel5Test < TestCase
  def test_agent_signature_check
    suffix          = rand(99999999999999999).to_s
    signature_name1 = 'sig name 1 äöüß ' + suffix
    signature_body1 = "--\nsig body 1 äöüß " + suffix
    signature_name2 = 'sig name 2 äöüß ' + suffix
    signature_body2 = "--\nsig body 2 äöüß " + suffix
    group_name1     = "group name 1 " + suffix
    group_name2     = "group name 2 " + suffix
    group_name3     = "group name 3 " + suffix

    tests = [
      {
        :name     => 'create groups and signatures',
        :action   => [

          {
            :execute => 'close_all_tasks',
          },

          # create signatures
          {
            :execute => 'create_signature',
            :name    => signature_name1,
            :body    => signature_body1,
          },
          {
            :execute => 'create_signature',
            :name    => signature_name2,
            :body    => signature_body2,
          },

          # create groups
          {
            :execute   => 'create_group',
            :name      => group_name1,
            :signature => signature_name1,
            :member    => [
              'master@example.com'
            ],
          },
          {
            :execute   => 'create_group',
            :name      => group_name2,
            :signature => signature_name2,
            :member    => [
              'master@example.com'
            ],
          },
          {
            :execute => 'create_group',
            :name    => group_name3,
            :member  => [
              'master@example.com'
            ],
          },
        ],
      },
      {
        :name     => 'check signature in new ticket',
        :action   => [

          # reload instances to get new group permissions
          {
            :execute => 'reload',
          },

          {
            :execute       => 'create_ticket',
            :group         => 'Users',
            :subject       => 'some subject 4 -  123äöü',
            :body          => 'some body 4 -  123äöü',
            :do_not_submit => true,
          },

          # check content
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => 'some body 4',
            :no_quote     => true,
            :match_result => true,
          },

          # select group
          {
            :execute => 'select',
            :css     => '.active [name="group_id"]',
            :value   => group_name1,
          },

          # select group
          {
            :execute => 'select',
            :css     => '.active [name="group_id"]',
            :value   => group_name1,
          },

          # check content
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => 'some body 4',
            :no_quote     => true,
            :match_result => true,
          },

          # check signature
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body1,
            :no_quote     => true,
            :match_result => false,
          },
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body2,
            :no_quote     => true,
            :match_result => false,
          },

          # select create channel
          {
            :execute => 'click',
            :css     => '.active [data-type="email-out"]',
          },

          # select group
          {
            :execute => 'select',
            :css     => '.active select[name="group_id"]',
            :value   => group_name1,
          },

          # check content
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => 'some body 4',
            :no_quote     => true,
            :match_result => true,
          },

          # check signature
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body1,
            :no_quote     => true,
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body2,
            :no_quote     => true,
            :match_result => false,
          },

          # select group
          {
            :execute => 'select',
            :css     => '.active select[name="group_id"]',
            :value   => group_name2,
          },

          # check content
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => 'some body 4',
            :no_quote     => true,
            :match_result => true,
          },

          # check signature
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body1,
            :no_quote     => true,
            :match_result => false,
          },
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body2,
            :no_quote     => true,
            :match_result => true,
          },

          # select group
          {
            :execute => 'select',
            :css     => '.active select[name="group_id"]',
            :value   => group_name3,
          },

          # check content
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => 'some body 4',
            :no_quote     => true,
            :match_result => true,
          },

          # check signature
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body1,
            :no_quote     => true,
            :match_result => false,
          },
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body2,
            :no_quote     => true,
            :match_result => false,
          },


          # select group
          {
            :execute => 'select',
            :css     => '.active select[name="group_id"]',
            :value   => group_name1,
          },

          # check content
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => 'some body 4',
            :no_quote     => true,
            :match_result => true,
          },

          # check signature
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body1,
            :no_quote     => true,
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body2,
            :no_quote     => true,
            :match_result => false,
          },

          # select create channel
          {
            :execute => 'click',
            :css     => '.active [data-type="phone-out"]',
          },

          # check content
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => 'some body 4',
            :no_quote     => true,
            :match_result => true,
          },

          # check signature
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body1,
            :no_quote     => true,
            :match_result => false,
          },
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body2,
            :no_quote     => true,
            :match_result => false,
          },
        ],
      },
      {
        :name     => 'check signature in zoom ticket',
        :action   => [

          {
            :execute => 'create_ticket',
            :group   => group_name1,
            :subject => 'some subject 5 -  123äöü',
            :body    => 'some body 5 -  123äöü',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },

          # execute reply
          {
            :execute => 'click',
            :css     => '.active [data-type="reply"]',
          },

          # check if signature exists
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body1,
            :no_quote     => true,
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body2,
            :no_quote     => true,
            :match_result => false,
          },

          # discard changes
          {
            :execute => 'click',
            :css     => '.active .js-reset',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },

          # check if signature exists
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body1,
            :no_quote     => true,
            :match_result => false,
          },
          {
            :execute      => 'match',
            :css          => '.active [data-name="body"]',
            :value        => signature_body2,
            :no_quote     => true,
            :match_result => false,
          },

        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'master@example.com' })
  end
end