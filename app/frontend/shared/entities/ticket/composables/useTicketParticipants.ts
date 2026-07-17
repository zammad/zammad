// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import { useTicketParticipantAddMutation } from '#shared/entities/ticket/graphql/mutations/participantAdd.api.ts'
import { useTicketParticipantRemoveMutation } from '#shared/entities/ticket/graphql/mutations/participantRemove.api.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import type { Ref } from 'vue'

export const useTicketParticipants = (ticket: Ref<TicketById | undefined>) => {
  const { isTicketAgent } = useTicketView(ticket)
  const session = useSessionStore()
  const application = useApplicationStore()
  const { notify } = useNotifications()

  const isEnabled = computed(() =>
    Boolean(application.config?.ticket_participants_enabled),
  )

  // Use agent-update access (not just read) — read-only agents must not see
  // Add/Remove controls that would fail server-side (mutations require agent_update_access?).
  const canManageParticipants = computed(() =>
    Boolean(ticket.value?.policy?.agentUpdateAccess) && isEnabled.value,
  )

  const participants = computed(() => {
    if (!ticket.value?.mentions?.edges) return []
    return ticket.value.mentions.edges
      // Exclude agents entirely (by role, not by current read access) — an agent
      // who lost group read access is NOT a customer participant.
      .filter(({ node }) => node.user.active && !node.user.permissions?.includes('ticket.agent'))
      .map(({ node }) => node.user)
  })

  const loading = ref(false)

  const addMutation = new MutationHandler(
    useTicketParticipantAddMutation({}),
  )
  const removeMutation = new MutationHandler(
    useTicketParticipantRemoveMutation({}),
  )

  const notifyError = (message: string) => {
    notify({ message, type: NotificationTypes.Error })
  }

  const addParticipant = async (ticketId: string, userId: string) => {
    loading.value = true
    try {
      const result = await addMutation.send({ ticketId, userId })
      return !!result?.ticketParticipantAdd?.participant
    } catch (error) {
      const msg = (error as any)?.getFirstErrorMessage?.() || (error as any)?.message || ''
      if (msg) notifyError(msg)
      return false
    } finally {
      loading.value = false
    }
  }

  const removeParticipant = async (ticketId: string, userId: string) => {
    loading.value = true
    try {
      const result = await removeMutation.send({ ticketId, userId })
      return !!result?.ticketParticipantRemove?.success
    } catch (error) {
      const msg = (error as any)?.getFirstErrorMessage?.() || (error as any)?.message || ''
      if (msg) notifyError(msg)
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    participants,
    loading,
    isEnabled,
    canManageParticipants,
    addParticipant,
    removeParticipant,
  }
}
