require 'test_helper'

class SettingTest < ActiveSupport::TestCase

  test 'basics' do
    Setting.create!(
      title: 'ABC API Token',
      name: 'abc_api_token',
      area: 'Integration::ABC',
      description: 'API Token for ABC to access ABC.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'abc_token',
            tag: 'input',
          },
        ],
      },
      state: 'abc',
      frontend: false
    )
    assert_equal(Setting.get('abc_api_token'), 'abc')
    assert(Setting.set('abc_api_token', 'new_abc'))
    assert_equal(Setting.get('abc_api_token'), 'new_abc')
    assert(Setting.reset('abc_api_token'))
    assert_equal(Setting.get('abc_api_token'), 'abc')
  end

  test 'cache reset via preferences' do
    Setting.create!(
      title: 'ABC API Token',
      name: 'abc_api_token',
      area: 'Integration::ABC',
      description: 'API Token for ABC to access ABC.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'abc_token',
            tag: 'input',
          },
        ],
      },
      state: '',
      preferences: {
        permission: ['admin.integration'],
        cache: ['abcGetVoipUsers'],
      },
      frontend: false
    )

    Cache.write('abcGetVoipUsers', { a: 1 })
    assert_equal(Cache.get('abcGetVoipUsers'), { a: 1 })

    Setting.set('abc_api_token', 'some_new_value')
    assert_nil(Cache.get('abcGetVoipUsers'))

  end

end
