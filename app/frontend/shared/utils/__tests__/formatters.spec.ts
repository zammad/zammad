// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getInitials, toClassName } from '../formatter.ts'

describe('getInitials', () => {
  it('returns ?? initials, if no arguments are present', () => {
    expect(getInitials()).toBe('??')
    expect(getInitials('', '', '')).toBe('??')
  })

  it('returns two letters from firstname, if no other are present', () => {
    expect(getInitials('Nicole')).toBe('NI')
    expect(getInitials('Nicole', '', '')).toBe('NI')
  })

  it('returns two letters from lastname, if no other are present', () => {
    expect(getInitials(undefined, 'Braun')).toBe('BR')
    expect(getInitials('', 'Braun', '')).toBe('BR')
  })

  it('returns two letters from email, if no other are present', () => {
    expect(getInitials(undefined, undefined, 'email@mail.com')).toBe('EM')
    expect(getInitials('', '', 'email@mail.com')).toBe('EM')
  })

  it('returns two letters from firstname and lastname', () => {
    expect(getInitials('Nicole', 'Braun')).toBe('NB')
    expect(getInitials('Martina', 'Lila', '')).toBe('ML')
    expect(getInitials('Nicole', 'Braun', 'email@mail.com')).toBe('NB')
  })

  it('returns lastname first initial for last_first format', () => {
    expect(getInitials('Nicole', 'Braun', '', '', '', 'last_first')).toBe('BN')
  })

  it('returns lastname first initial for last_first_comma format', () => {
    expect(getInitials('Nicole', 'Braun', '', '', '', 'last_first_comma')).toBe('BN')
  })

  it('returns firstname lastname initial for first_last format', () => {
    expect(getInitials('Nicole', 'Braun', '', '', '', 'first_last')).toBe('NB')
  })

  it('ignores format when only one name is present', () => {
    expect(getInitials('Nicole', '', '', '', '', 'last_first')).toBe('NI')
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
