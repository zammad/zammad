# encoding: utf-8
require 'test_helper'
 
class UserTest < ActiveSupport::TestCase
  test 'user' do
    tests = [
      {
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
          :email     => 'some@example.com',
          :login     => 'some@example.com',
        },
      },
      {
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
          :email     => 'some@example.com',
          :login     => 'some@example.com',
        },
      },
      {
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
          :email     => 'some@example.com',
          :login     => 'some@example.com',
        },
      },
      {
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
        :create => {
          :firstname     => '',
          :lastname      => '',
          :email         => 'firstname.lastname@example.com',
          :login         => 'login',
          :updated_by_id => 1,
          :created_by_id => 1,
        },
        :create_verify => {
          :firstname => 'Firstname',
          :lastname  => 'Lastname',
          :email     => 'firstname.lastname@example.com',
          :login     => 'login',
        },
      },
      {
        :create => {
          :firstname     => '',
          :lastname      => '',
          :email         => 'FIRSTNAME.lastname@example.com',
          :login         => 'login',
          :updated_by_id => 1,
          :created_by_id => 1,
        },
        :create_verify => {
          :firstname => 'Firstname',
          :lastname  => 'Lastname',
          :email     => 'firstname.lastname@example.com',
          :login     => 'login',
        },
      },
      {
        :create => {
          :firstname     => nil,
          :lastname      => nil,
          :email         => 'FIRSTNAME.lastname@example.com',
          :login         => 'login',
          :updated_by_id => 1,
          :created_by_id => 1,
        },
        :create_verify => {
          :firstname => 'Firstname',
          :lastname  => 'Lastname',
          :email     => 'firstname.lastname@example.com',
          :login     => 'login',
        },
      },
    ]

    tests.each { |test|

      user = User.create( test[:create] )

      test[:create_verify].each { |key, value|
        assert_equal( user[key], value )
      }

      user.destroy
    }    
  end
end

