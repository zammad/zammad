# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormSchema::Form::Mobile::Login) do
  subject(:schema) { described_class.new(context: context).schema }

  let(:context) { Struct.new(:current_user, :current_user?).new(User.find(1)) }
  let(:expected) do
    [
      {
        type:     'text',
        name:     'login',
        label:    __('Username / Email'),
        required: true,
        props:    {
          placeholder: __('Username / Email'),
        },
      },
      {
        type:     'password',
        label:    __('Password'),
        name:     'password',
        required: true,
        props:    {
          placeholder: __('Password'),
        },
      },
      {
        isLayout: true,
        element:  'div',
        attrs:    {
          class: 'mt-2.5 flex grow items-center justify-between text-white',
        },
        children: [
          {
            type:  'checkbox',
            label: __('Remember me'),
            name:  'remember_me',
            props: {},
          },
          {
            isLayout:  true,
            component: 'CommonLink',
            props:     {
              class: 'text-right !text-white',
              link:  '/#password_reset',
            },
            children:  __('Forgot password?'),
          },
        ],
      },
    ]
  end

  it 'returns login schema information' do
    expect(schema).to eq(expected)
  end
end
