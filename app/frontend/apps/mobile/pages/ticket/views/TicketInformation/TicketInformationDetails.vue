<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/attribute-hyphenation */

import { computed, nextTick, onMounted, onUnmounted, watch } from 'vue'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonUsersList from '#mobile/components/CommonUsersList/CommonUsersList.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useSessionStore } from '#shared/stores/session.ts'
import CommonShowMoreButton from '#mobile/components/CommonShowMoreButton/CommonShowMoreButton.vue'
import CommonSectionMenuItem from '#mobile/components/CommonSectionMenu/CommonSectionMenuItem.vue'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import { waitForConfirmation } from '#shared/utils/confirmation.ts'
import TicketObjectAttributes from '../../components/TicketDetailView/TicketObjectAttributes.vue'
import TicketTags from '../../components/TicketDetailView/TicketTags.vue'
import { useTicketInformation } from '../../composable/useTicketInformation.ts'
import { useTicketSubscribe } from '../../composable/useTicketSubscribe.ts'

const { attributes: objectAttributes } = useObjectAttributes(
  EnumObjectManagerObjects.Ticket,
)

const {
  form,
  initialFormTicketValue,
  ticket,
  updateFormLocation,
  ticketQuery,
  canUpdateTicket,
} = useTicketInformation()

const ticketFormGroupNode = computed(() => {
  return form.value?.formNode?.at('ticket')
})

const discardTicketEditDialog = async () => {
  if (!ticketFormGroupNode.value) return

  const confirmed = await waitForConfirmation(
    __('Are you sure? You have unsaved changes that will get lost.'),
    {
      buttonTitle: __('Discard changes'),
      buttonVariant: 'danger',
    },
  )

  if (!confirmed) return

  form.value?.resetForm(
    initialFormTicketValue,
    ticket.value,
    { resetDirty: true },
    ticketFormGroupNode.value,
  )
}

onMounted(() => {
  updateFormLocation('[data-ticket-edit-form]')
})

onUnmounted(() => {
  updateFormLocation('body')
})

const {
  canManageSubscription,
  isSubscribed,
  isSubscriptionLoading,
  toggleSubscribe,
} = useTicketSubscribe(ticket)

const variants = {
  true: __('yes'),
  false: __('no'),
}

let isOutsideUpdate = false
watch(
  () => isSubscribed.value,
  () => {
    isOutsideUpdate = true
    nextTick(() => {
      isOutsideUpdate = false
    })
  },
)

const handleToggleInput = async () => {
  // do not trigger update, if value was changed from the outside,
  // and not by clicking on toggle button, otherwise it goes into infinite loop
  if (isOutsideUpdate) return false
  return toggleSubscribe()
}

const session = useSessionStore()

const subscribers = computed(() => {
  if (!ticket.value?.mentions) return []
  const subscribers = []
  for (const { node } of ticket.value.mentions.edges) {
    if (node.user.id !== session.userId) {
      subscribers.push(node.user)
    }
  }
  return subscribers
})

const totalSubscribers = computed(() => {
  if (!ticket.value?.mentions) return 0
  const hasMe = ticket.value.mentions.edges.some(
    ({ node }) => node.user.id === session.userId,
  )
  // -1 for current user, who is shown as toggler
  return ticket.value.mentions.totalCount - (hasMe ? 1 : 0)
})

const loadingTicket = ticketQuery.loading()
const loadMoreMentions = () => {
  ticketQuery.refetch({
    mentionsCount: null,
  })
}

const { isTicketAgent, isTicketEditable } = useTicketView(ticket)
</script>

<template>
  <CommonLoader :loading="!ticket" />

  <div data-ticket-edit-form />

  <FormKit
    v-if="ticketFormGroupNode?.context?.state.dirty"
    wrapper-class="mt-4 mb-4 flex grow justify-center items-center"
    input-class="py-2 px-4 w-full h-14 text-base !text-red-bright formkit-variant-primary:bg-red-dark rounded-xl select-none"
    type="button"
    name="discardTicketInformation"
    @click="discardTicketEditDialog"
  >
    {{ $t('Discard your unsaved changes') }}
  </FormKit>

  <ObjectAttributes
    v-if="!canUpdateTicket && ticket"
    :object="ticket"
    :attributes="objectAttributes"
    :skip-attributes="['title']"
    :accessors="{
      state_id: 'state.name',
      priority_id: 'priority.name',
      owner_id: 'owner.fullname',
      group_id: 'group.name',
    }"
  />

  <TicketObjectAttributes v-if="isTicketAgent && ticket" :ticket="ticket" />

  <TicketTags
    v-if="isTicketAgent && isTicketEditable && ticket"
    :ticket="ticket"
  />

  <CommonSectionMenu v-else-if="ticket?.tags?.length">
    <CommonSectionMenuItem :label="__('Tags')">
      {{ ticket.tags.join(', ') }}
    </CommonSectionMenuItem>
  </CommonSectionMenu>

  <CommonSectionMenu
    v-if="canManageSubscription"
    :header-label="__('Subscribers')"
  >
    <!-- Currently only modelValue is working: https://github.com/formkit/formkit/issues/629 -->
    <FormKit
      type="toggle"
      :modelValue="isSubscribed"
      :label="__('Get notified')"
      :variants="variants"
      :disabled="isSubscriptionLoading"
      :outer-class="{
        '!px-0': true,
        'border-b border-white/10': subscribers.length,
      }"
      wrapper-class="!px-0"
      @input-raw="handleToggleInput"
    >
      <template #label="context">
        <label :for="context.id" :class="context.classes.label">
          <CommonUserAvatar
            v-if="session.user"
            class="ltr:mr-3 rtl:ml-3"
            :entity="session.user"
          />
          {{ context.label }}
        </label>
      </template>
    </FormKit>
    <CommonUsersList :users="subscribers" />
    <CommonShowMoreButton
      :entities="subscribers"
      :total-count="totalSubscribers"
      :disabled="loadingTicket"
      @click="loadMoreMentions"
    />
  </CommonSectionMenu>
</template>
