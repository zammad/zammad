// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  emailFilterValueValidator,
  formattedPhoneFilterValueValidator,
  phoneFilterValueValidator,
} from '../filterValueValidators.ts'

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

describe('formattedPhoneFilterValueValidator', () => {
  it.each(['+49 30 609854180', '030 609854180', '+49 (0)30 123-456', '0049.30.609854180'])(
    'accepts %s',
    (number) => {
      expect(formattedPhoneFilterValueValidator(number)).toBe(true)
    },
  )

  it.each(['12345', 'Zammad2024', '+49 30 6098 ext', testEmailAddress, '30+609854180'])(
    'rejects %s',
    (value) => {
      expect(formattedPhoneFilterValueValidator(value)).toBe(false)
    },
  )
})
