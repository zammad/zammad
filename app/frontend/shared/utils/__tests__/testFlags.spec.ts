// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { waitForTimeout } from '@tests/support/utils'
import testFlags from '../testFlags'

describe('TestFlags', () => {
  it('handles test flags properly', async () => {
    expect.assertions(5)
    expect(testFlags.get('not_defined')).toBe(false)
    await testFlags.set('defined')
    expect(testFlags.get('defined')).toBe(true)
    await testFlags.clear('defined')
    expect(testFlags.get('defined')).toBe(false)
    await testFlags.set('defined')
    expect(testFlags.get('defined')).toBe(true)

    await waitForTimeout(0)

    // Test the clearing side effect of get()
    expect(testFlags.get('defined')).toBe(false)
  })
})
