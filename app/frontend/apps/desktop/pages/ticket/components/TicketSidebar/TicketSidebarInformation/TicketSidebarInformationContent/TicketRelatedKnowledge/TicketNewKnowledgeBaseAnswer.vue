<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'
import { ref } from 'vue'

import { useKnowledgeBaseAnswerLinks } from './composables/useKnowledgeBaseAnswerLinks.ts'

import type { FormKitNode } from '@formkit/core'

const props = defineProps<{
  linkedAnswerIds: ID[]
  ticketId: ID
  targetType: string
}>()

const active = defineModel<boolean>('newKnowledgeBaseAnswer')

const formNode = ref<FormKitNode>()

const { linkAnswer } = useKnowledgeBaseAnswerLinks(props.ticketId, props.targetType)

const close = () => {
  active.value = false
}

const onNode = (node: FormKitNode) => {
  formNode.value = node

  // Link the picked answer as soon as the field commits a selection
  node.on('commit', ({ payload }: { payload: string | null }) => {
    if (!payload) return

    linkAnswer(payload).then(close)
  })
}

// The field calls this when its dropdown is closed/dismissed
const onDeactivate = () => {
  if (formNode.value?.value) return

  close()
}
</script>

<template>
  <FormKit
    :classes="{
      outer: 'w-full',
    }"
    type="knowledgeBaseAnswer"
    :exclude="linkedAnswerIds"
    :on-deactivate="onDeactivate"
    @node="onNode"
  />
</template>
