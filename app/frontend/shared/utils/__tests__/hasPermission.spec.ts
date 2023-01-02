// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import hasPermission from '../hasPermission'

describe('hasPermission', () => {
  it('no access when permissions are required, but no permission are present', () => {
    expect(hasPermission('ticket.agent', [])).toBe(false)
  })

  it('access granted when permissions are required and needed permission exists', () => {
    expect(hasPermission('ticket.agent', ['ticket.agent'])).toBe(true)
  })

  it('access granted when only parent permission exists', () => {
    expect(hasPermission('ticket.agent', ['ticket'])).toBe(true)
  })

  it('access granted when multiple permissions exists', () => {
    expect(
      hasPermission('ticket.agent', ['ticket.customer', 'ticket.agent']),
    ).toBe(true)
  })

  it('access granted when multiple required permissions exists', () => {
    expect(
      hasPermission(['ticket.agent', 'ticket.customer'], ['ticket.agent']),
    ).toBe(true)
  })

  describe('with wildcard usage', () => {
    it('access granted if any permission gives access', () => {
      expect(hasPermission('*', [])).toBe(true)
    })

    it('no access for any sub permission, without a sub permission', () => {
      expect(hasPermission('admin.*', [])).toBe(false)
    })

    it('access granted when a sub permission exists', () => {
      expect(hasPermission('ticket.*', ['ticket.agent'])).toBe(true)
    })

    it('access granted when only parent permission exists', () => {
      expect(hasPermission('ticket.*', ['ticket'])).toBe(true)
    })

    it('no access when only similar parent permission exists', () => {
      expect(hasPermission('ticket.*', ['ticketing'])).toBe(false)
    })

    it('access granted with wildcard in a deeper level and when only parent permission exists', () => {
      expect(hasPermission('ticket.agent.*', ['ticket'])).toBe(true)
    })

    it('access granted with wildcard in the middle of a requird permission', () => {
      expect(hasPermission('ticket.*.test', ['ticket.agent.test'])).toBe(true)
    })

    it('access granted with a complex structure and wildcard usage', () => {
      expect(
        hasPermission('ticket.*.test.*.view', ['ticket.agent.test.foo.view']),
      ).toBe(true)
    })

    it('no access with a complex structure and wildcard usage', () => {
      expect(
        hasPermission('ticket.*.test.*.view', ['ticket.agent.asd.foo.view']),
      ).toBe(false)
    })
  })

  describe('with a "AND" combination', () => {
    it('access granted when both combinated permission exists', () => {
      expect(
        hasPermission('ticket.agent+ticket.customer', [
          'ticket.customer',
          'ticket.agent',
        ]),
      ).toBe(true)
    })

    it('no access when not both combinated permission exists', () => {
      expect(
        hasPermission('ticket.agent+ticket.customer', [
          'ticket.customer',
          'admin',
        ]),
      ).toBe(false)
    })
  })

  describe('with a "AND" combination together with a wildcard', () => {
    it('access granted when both combinated permission exists', () => {
      expect(
        hasPermission('ticket.*+admin.chat', ['ticket.customer', 'admin.chat']),
      ).toBe(true)
    })
  })
})
