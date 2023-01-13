<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import CommonTicketPriorityIndicator from '@shared/components/CommonTicketPriorityIndicator/CommonTicketPriorityIndicator.vue'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import CommonTicketStateIndicator from '@shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import type { TicketById } from '@shared/entities/ticket/types'
import TicketDetailViewUpdateButton from './TicketDetailViewUpdateButton.vue'
import { useTicketInformation } from '../../composable/useTicketInformation'

const {
  ticket,
  newTicketArticlePresent,
  isTicketFormGroupValid,
  isArticleFormGroupValid,
  formSubmit,
  showArticleReplyDialog,
} = useTicketInformation()

interface Props {
  ticket: TicketById
}

const props = defineProps<Props>()

const router = useRouter()

const customer = computed(() => {
  const { customer } = props.ticket
  if (!customer) return ''
  const { fullname } = customer
  if (fullname === '-') return ''
  return fullname
})

const submitForm = () => {
  if (!isTicketFormGroupValid.value) {
    router.push(`/tickets/${props.ticket.internalId}/information`)
  } else if (newTicketArticlePresent.value && !isArticleFormGroupValid.value) {
    showArticleReplyDialog()
  }

  formSubmit()
}
</script>

<template>
  <div class="relative border-b-[0.5px] border-white/10 bg-gray-600/90">
    <CommonLink
      class="flex py-5 px-4"
      data-test-id="title-content"
      :link="`/tickets/${ticket.internalId}/information`"
    >
      <div class="ltr:mr-3 rtl:ml-3">
        <CommonUserAvatar :entity="ticket.customer" />
      </div>
      <div class="overflow-hidden ltr:mr-1 rtl:ml-1">
        <div class="flex text-sm leading-4 text-gray-100">
          <div
            class="overflow-hidden text-ellipsis whitespace-nowrap"
            :class="{
              'max-w-[80vw]': !ticket.organization,
              'max-w-[40vw]': ticket.organization,
            }"
          >
            {{ customer }}
          </div>
          <template v-if="ticket.organization">
            <div class="px-1">·</div>
            <div
              class="max-w-[40vw] overflow-hidden text-ellipsis whitespace-nowrap"
            >
              {{ ticket.organization.name }}
            </div>
          </template>
        </div>
        <h1 class="break-words text-xl font-bold leading-7 line-clamp-3">
          {{ ticket.title }}
        </h1>
        <div class="mt-2 flex gap-2">
          <CommonTicketStateIndicator
            :status="ticket.state.stateType.name"
            :label="ticket.state.name"
            pill
          />
          <CommonTicketPriorityIndicator :priority="ticket.priority" />
        </div>
      </div>
      <CommonIcon
        name="mobile-chevron-right"
        size="base"
        class="shrink-0 self-center ltr:ml-auto ltr:-mr-2 rtl:mr-auto"
        decorative
      />
    </CommonLink>
    <TicketDetailViewUpdateButton
      class="!absolute right-4 -bottom-5"
      @click.prevent="submitForm"
    />
  </div>
</template>
