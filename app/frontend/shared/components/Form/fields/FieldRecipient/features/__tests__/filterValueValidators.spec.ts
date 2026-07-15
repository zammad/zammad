// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { emailFilterValueValidator, phoneFilterValueValidator } from '../filterValueValidators.ts'

const testEmailAddress = 'nicole.braun@zammad.org'
const testPhoneNumber = '+490123456789'

describe('emailFilterValueValidator', () => {
  it('returns true on valid email address', () => {
    expect(emailFilterValueValidator(testEmailAddress)).toBe(true)
  })

  it('returns false on invalid email address', () => {
    expect(emailFilterValueValidator('foobar')).toBe(false)
  })
})

describe('phoneFilterValueValidator', () => {
  it('returns true on valid phone number', () => {
    expect(phoneFilterValueValidator(testPhoneNumber)).toBe(true)
  })

  it('returns false on invalid phone number', () => {
    expect(phoneFilterValueValidator('Zammad2024')).toBe(false)
  })
})
