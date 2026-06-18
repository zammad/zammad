<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, watch } from 'vue'

import { useTicketParticipants } from '#shared/entities/ticket/composables/useTicketParticipants.ts'
import {
  type TicketSidebarProps,
  type TicketSidebarEmits,
} from '#desktop/pages/ticket/types/sidebar.ts'
import { useAutocompleteSearchGenericLazyQuery } from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/generic.api.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { EnumSearchableModels } from '#shared/graphql/types.ts'

import TicketSidebarWrapper from '../TicketSidebarWrapper.vue'

import {
  TicketSidebarButtonBadgeType,
  type TicketSidebarButtonBadgeDetails,
} from '#desktop/pages/ticket/types/sidebar.ts'

const props = defineProps<TicketSidebarProps>()
const emit = defineEmits<TicketSidebarEmits>()

const ticket = computed(() => props.context.ticket?.value)

const {
  participants,
  loading,
  isEnabled,
  canManageParticipants,
  addParticipant,
  removeParticipant,
} = useTicketParticipants(ticket)

const badge = computed<TicketSidebarButtonBadgeDetails | undefined>(() => {
  if (participants.value.length === 0) return

  return {
    type: TicketSidebarButtonBadgeType.Default,
    value: participants.value.length,
    label: __('Participants'),
  }
})

const showAdd = ref(false)
const searchInput = ref('')
const searchResults = ref<Array<{ id: string; label: string }>>([])
const searchLoading = ref(false)

const searchHandler = new QueryHandler(
  useAutocompleteSearchGenericLazyQuery(undefined, { enabled: false }),
)

let searchTimeout: ReturnType<typeof setTimeout> | null = null

watch(searchInput, (val) => {
  if (searchTimeout) clearTimeout(searchTimeout)
  if (val.length < 2) {
    searchResults.value = []
    return
  }
  searchLoading.value = true
  searchTimeout = setTimeout(async () => {
    try {
      const result = await searchHandler.query({
        variables: {
          input: {
            query: val,
            limit: 10,
            onlyIn: [EnumSearchableModels.User],
          },
        },
        fetchPolicy: 'no-cache',
      })
      if (result?.data?.autocompleteSearchGeneric) {
        searchResults.value = result.data.autocompleteSearchGeneric
          .filter(
            (item): item is typeof item & { object: { __typename: 'User'; id: string } } =>
              item.object?.__typename === 'User',
          )
          .map((item) => ({
            id: item.object.id,
            label: item.label,
          }))
      }
    } catch (e) {
      console.error('Search failed:', e)
    } finally {
      searchLoading.value = false
    }
  }, 300)
})

const handleAdd = async (userId: string) => {
  if (!ticket.value?.id) return
  const success = await addParticipant(ticket.value.id, userId)
  if (success) {
    searchInput.value = ''
    showAdd.value = false
    searchResults.value = []
  }
}

const handleRemove = async (userId: string) => {
  if (!ticket.value?.id) return
  await removeParticipant(ticket.value.id, userId)
}

emit('show')
</script>

<template>
  <TicketSidebarWrapper
    v-if="isEnabled"
    :key="sidebar"
    :sidebar="sidebar"
    :sidebar-plugin="sidebarPlugin"
    :selected="selected"
    :context="context"
    :badge="badge"
    @hide="emit('hide')"
  >
    <div class="space-y-2">
      <div v-if="canManageParticipants" class="flex justify-end">
        <button class="btn btn--xs" @click="showAdd = !showAdd">
          {{ showAdd ? $t('Cancel') : $t('+ Add') }}
        </button>
      </div>

      <div v-if="showAdd" class="space-y-1">
        <input
          v-model="searchInput"
          :placeholder="$t('Search users...')"
          class="input input--small w-full"
        />
        <div v-if="searchLoading" class="text-gray text-sm">
          {{ $t('Searching...') }}
        </div>
        <div
          v-for="user in searchResults"
          :key="user.id"
          class="flex items-center justify-between cursor-pointer rounded p-1 hover:bg-gray-100"
          @click="handleAdd(user.id)"
        >
          <span class="text-sm">
            {{ user.label }}
          </span>
          <span class="text-xs text-gray">+</span>
        </div>
      </div>

      <div v-if="loading" class="text-gray">
        {{ $t('Loading...') }}
      </div>
      <div v-else-if="participants.length === 0" class="text-gray">
        {{ $t('No participants yet.') }}
      </div>
      <div v-else class="space-y-1">
        <div v-for="participant in participants" :key="participant.id" class="flex items-center justify-between">
          <span class="text-sm">
            {{ participant.fullname || participant.firstname || participant.id }}
          </span>
          <button
            v-if="canManageParticipants"
            class="btn btn--xs btn--text"
            @click="handleRemove(participant.id)"
          >
            ✕
          </button>
        </div>
      </div>
    </div>
  </TicketSidebarWrapper>
</template>
