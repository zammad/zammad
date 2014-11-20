# encoding: utf-8
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'user' do
    tests = [
      {
        :name => '#1 - simple create',
        :create => {
          :firstname     => 'Firstname',
          :lastname      => 'Lastname',
          :email         => 'some@example.com',
          :login         => 'some@example.com',
          :updated_by_id => 1,
          :created_by_id => 1,
        },
        :create_verify => {
          :firstname => 'Firstname',
          :lastname  => 'Lastname',
          :image     => 'none',
          :email     => 'some@example.com',
          :login     => 'some@example.com',
        },
      },
      {
        :name => '#2 - simple create - no lastname',
        :create => {
          :firstname     => 'Firstname Lastname',
          :lastname      => '',
          :email         => 'some@example.com',
          :login         => 'some@example.com',
          :updated_by_id => 1,
          :created_by_id => 1,
        },
        :create_verify => {
          :firstname => 'Firstname',
          :lastname  => 'Lastname',
          :image     => 'none',
          :email     => 'some@example.com',
          :login     => 'some@example.com',
        },
      },
      {
        :name => '#3 - simple create - nil as lastname',
        :create => {
          :firstname     => 'Firstname Lastname',
          :lastname      => nil,
          :email         => 'some@example.com',
          :login         => 'some@example.com',
          :updated_by_id => 1,
          :created_by_id => 1,
        },
        :create_verify => {
          :firstname => 'Firstname',
          :lastname  => 'Lastname',
          :image     => 'none',
          :email     => 'some@example.com',
          :login     => 'some@example.com',
        },
      },
      {
        :name => '#4 - simple create - no lastname, firstname with ","',
        :create => {
          :firstname     => 'Lastname, Firstname',
          :lastname      => '',
          :email         => 'some@example.com',
          :login         => 'some@example.com',
          :updated_by_id => 1,
          :created_by_id => 1,
        },
        :create_verify => {
          :firstname => 'Firstname',
          :lastname  => 'Lastname',
          :email     => 'some@example.com',
          :login     => 'some@example.com',
        },
      },
      {
        :name => '#5 - simple create - no lastname/firstname',
        :create => {
          :firstname     => '',
          :lastname      => '',
          :email         => 'firstname.lastname@example.com',
          :login         => 'login-1',
          :updated_by_id => 1,
          :created_by_id => 1,
        },
        :create_verify => {
          :firstname => 'Firstname',
          :lastname  => 'Lastname',
          :email     => 'firstname.lastname@example.com',
          :login     => 'login-1',
        },
      },
      {
        :name => '#6 - simple create - no lastname/firstnam',
        :create => {
          :firstname     => '',
          :lastname      => '',
          :email         => 'FIRSTNAME.lastname@example.com',
          :login         => 'login-2',
          :updated_by_id => 1,
          :created_by_id => 1,
        },
        :create_verify => {
          :firstname => 'Firstname',
          :lastname  => 'Lastname',
          :email     => 'firstname.lastname@example.com',
          :login     => 'login-2',
        },
      },
      {
        :name => '#7 - simple create - nill as fristname and lastname',
        :create => {
          :firstname     => nil,
          :lastname      => nil,
          :email         => 'FIRSTNAME.lastname@example.com',
          :login         => 'login-3',
          :updated_by_id => 1,
          :created_by_id => 1,
        },
        :create_verify => {
          :firstname => 'Firstname',
          :lastname  => 'Lastname',
          :email     => 'firstname.lastname@example.com',
          :login     => 'login-3',
        },
      },
      {
        :name => '#8 - update with avatar check',
        :create => {
          :firstname     => 'Bob',
          :lastname      => 'Smith',
          :email         => 'bob.smith@example.com',
          :login         => 'login-4',
          :updated_by_id => 1,
          :created_by_id => 1,
        },
        :create_verify => {
          :firstname => 'Bob',
          :lastname  => 'Smith',
          :image     => 'none',
          :image_md5 => '76fdc28c07e4f3d7802b75aacfccdf6a',
          :email     => 'bob.smith@example.com',
          :login     => 'login-4',
        },
        :update => {
          :email => 'unit-test1@znuny.com',
        },
        :update_verify => {
          :firstname => 'Bob',
          :lastname  => 'Smith',
          :image     => 'a6f7f7f9dac25b2c023d403ef998801c',
          :image_md5 => 'a6f7f7f9dac25b2c023d403ef998801c',
          :email     => 'unit-test1@znuny.com',
          :login     => 'login-4',
        }
      },
      {
        :name => '#9 - update create with avatar check',
        :create => {
          :firstname     => 'Bob',
          :lastname      => 'Smith',
          :email         => 'unit-test2@znuny.com',
          :login         => 'login-5',
          :updated_by_id => 1,
          :created_by_id => 1,
        },
        :create_verify => {
          :firstname => 'Bob',
          :lastname  => 'Smith',
          :image     => '8765a1ac93f54405d8dfdd856c48c31f',
          :image_md5 => '8765a1ac93f54405d8dfdd856c48c31f',
          :email     => 'unit-test2@znuny.com',
          :login     => 'login-5',
        },
        :update => {
          :email => 'unit-test1@znuny.com',
        },
        :update_verify => {
          :firstname => 'Bob',
          :lastname  => 'Smith',
          :image     => 'a6f7f7f9dac25b2c023d403ef998801c',
          :image_md5 => 'a6f7f7f9dac25b2c023d403ef998801c',
          :email     => 'unit-test1@znuny.com',
          :login     => 'login-5',
        }
      },
    ]

    tests.each { |test|

      # check if user exists
      user = User.where( :login => test[:create][:login] ).first
      if user
        user.destroy
      end

      user = User.create( test[:create] )

      test[:create_verify].each { |key, value|
        next if key == :image_md5
        assert_equal( value, user[key], "create check #{ key } in (#{ test[:name] })" )
      }
      if test[:create_verify][:image_md5]
        file = user.get_image
        file_md5 = Digest::MD5.hexdigest( file[:content] )
        assert_equal( test[:create_verify][:image_md5], file_md5, "create avatar md5 check in (#{ test[:name] })"  )
      end
      if test[:update]
        user.update_attributes( test[:update] )

        test[:update_verify].each { |key, value|
          next if key == :image_md5
          assert_equal( value, user[key], "update check #{ key } in (#{ test[:name] })"  )
        }

        if test[:update_verify][:image_md5]
          file = user.get_image
          file_md5 = Digest::MD5.hexdigest( file[:content] )
          assert_equal( test[:update_verify][:image_md5], file_md5, "update avatar md5 check in (#{ test[:name] })"  )
        end
      end

      user.destroy
    }
  end
end

