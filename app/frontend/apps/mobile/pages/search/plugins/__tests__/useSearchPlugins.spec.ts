// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '@shared/stores/session'
import { useSearchPlugins } from '../index'

vi.mock('@shared/stores/session', () => {
  return {
    useSessionStore: vi.fn(() => ({
      hasPermission: () => true,
    })),
  }
})

describe('plugins are returned correctly', () => {
  it('should return all search plugins', () => {
    const plugins = useSearchPlugins()

    expect(plugins).toEqual({
      ticket: expect.objectContaining({
        order: 100,
        link: '/tickets/#{internalId}',
      }),
      user: expect.objectContaining({
        order: 200,
        link: '/users/#{internalId}',
      }),
      organization: expect.objectContaining({
        order: 300,
        link: '/organizations/#{internalId}',
      }),
    })
  })

  it("don't return tickets when user has no permission", () => {
    vi.mocked(useSessionStore).mockReturnValue({
      hasPermission: (permissions: string[]) => {
        if (permissions.includes('ticket.agent')) {
          return false
        }
        return true
      },
    } as any)

    const plugins = useSearchPlugins()

    expect(plugins).not.toHaveProperty('organization')
  })
})
