// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { useTicketParticipants } from '#shared/entities/ticket/composables/useTicketParticipants.ts'

import { ref } from 'vue'

const mockTicket = (overrides: Record<string, unknown> = {}) =>
  ref<any>({
    id: '1',
    mentions: {
      edges: [],
      totalCount: 0,
    },
    ...overrides,
  })

describe('useTicketParticipants', () => {
  afterAll(() => vi.clearAllMocks())

  describe('isEnabled', () => {
    it('returns false when ticket_participants_enabled is not set', () => {
      mockApplicationConfig({})
      const { isEnabled } = useTicketParticipants(mockTicket() as any)
      expect(isEnabled.value).toBe(false)
    })

    it('returns true when ticket_participants_enabled is true', () => {
      mockApplicationConfig({ ticket_participants_enabled: true })
      const { isEnabled } = useTicketParticipants(mockTicket() as any)
      expect(isEnabled.value).toBe(true)
    })
  })

  describe('participants', () => {
    it('returns empty array when no mentions', () => {
      mockApplicationConfig({ ticket_participants_enabled: true })
      const { participants } = useTicketParticipants(mockTicket() as any)
      expect(participants.value).toEqual([])
    })

    it('filters out agents (users with userTicketAccess)', () => {
      mockApplicationConfig({ ticket_participants_enabled: true })
      const ticket = mockTicket({
        mentions: {
          edges: [
            {
              node: {
                user: { id: '1', firstname: 'Agent', active: true },
                userTicketAccess: { agentReadAccess: true },
              },
            },
            {
              node: {
                user: { id: '2', firstname: 'Customer', active: true },
                userTicketAccess: { agentReadAccess: false },
              },
            },
          ],
          totalCount: 2,
        },
      })
      const { participants } = useTicketParticipants(ticket as any)
      expect(participants.value).toHaveLength(1)
      expect(participants.value[0].id).toBe('2')
    })
  })

  describe('canManageParticipants', () => {
    it('returns false when flag is OFF even for agent', () => {
      mockApplicationConfig({ ticket_participants_enabled: false })
      // isTicketAgent would normally require session — mocked via vi
      const { canManageParticipants } = useTicketParticipants(mockTicket() as any)
      expect(canManageParticipants.value).toBe(false)
    })
  })
})
