// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getInitials, toClassName } from '../formatter.ts'

describe('getInitials', () => {
  it('returns ?? initials, if no arguments are present', () => {
    expect(getInitials()).toBe('??')
    expect(getInitials('', '', '')).toBe('??')
  })

  it('returns two letters from firstname, if no other are present', () => {
    expect(getInitials('John')).toBe('JO')
    expect(getInitials('John', '', '')).toBe('JO')
  })

  it('returns two letters from lastname, if no other are present', () => {
    expect(getInitials(undefined, 'Doe')).toBe('DO')
    expect(getInitials('', 'Doe', '')).toBe('DO')
  })

  it('returns two letters from email, if no other are present', () => {
    expect(getInitials(undefined, undefined, 'email@mail.com')).toBe('EM')
    expect(getInitials('', '', 'email@mail.com')).toBe('EM')
  })

  it('returns two letters from firstname and lastname', () => {
    expect(getInitials('John', 'Doe')).toBe('JD')
    expect(getInitials('John', 'Doe', '')).toBe('JD')
    expect(getInitials('John', 'Doe', 'email@mail.com')).toBe('JD')
  })

  it('returns last two numbers from phone and mobile', () => {
    expect(getInitials('', '', '', '490123456789')).toBe('89')
    expect(getInitials('', '', '', '', '491234567890')).toBe('90')
  })
})

describe('toClassName', () => {
  it('convert relation to class name', () => {
    expect(toClassName('TicketState')).toBe('Ticket::State')
  })
})
