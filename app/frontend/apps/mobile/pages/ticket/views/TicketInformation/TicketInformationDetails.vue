<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue'
import ObjectAttributes from '@shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useObjectAttributes } from '@shared/entities/object-attributes/composables/useObjectAttributes'
import { EnumObjectManagerObjects } from '@shared/graphql/types'
import { getFocusableElements } from '@shared/utils/getFocusableElements'
import type { FormKitNode } from '@formkit/core'
import { useTicketInformation } from '../../composable/useTicketInformation'

const { attributes: objectAttributes } = useObjectAttributes(
  EnumObjectManagerObjects.Ticket,
)

const { ticket, formVisible, form, canUpdateTicket } = useTicketInformation()

const waitForFormSettled = () => {
  // will resolve after ticket is loaded with graphql and form is mounted
  return new Promise<FormKitNode>((resolve) => {
    const interval = setInterval(() => {
      const formNode = form.value?.formNode
      if (!formNode) return
      clearInterval(interval)
      formNode.settled.then(() => resolve(formNode))
    })
  })
}

onMounted(async () => {
  formVisible.value = true

  await waitForFormSettled()
  const formElement = document.querySelector(
    '#form-ticket-edit',
  ) as HTMLFormElement
  const fields = getFocusableElements(formElement)

  fields[0]?.focus()
})

onUnmounted(() => {
  formVisible.value = false
})
</script>

<template>
  <div data-ticket-edit-form />

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
  <!-- TODO subscribe -->
</template>
