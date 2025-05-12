<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import Form from '#shared/components/Form/Form.vue'
import { useForm } from '#shared/components/Form/useForm.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import type { SubmitData } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/types.ts'

import type { FormKitNode } from '@formkit/core'

interface Props {
  name: string
  icon: string
  label: string
  inputPlaceholder: string
  issueLinks: string[]
  onSubmit: (link: string) => Promise<unknown>
}

const props = defineProps<Props>()

const { form } = useForm()

const validationRuleUrlAlreadyExists = (node: FormKitNode) => {
  if (!node.value) return true

  return !props.issueLinks.includes(node.value as string)
}

const linkSchema = [
  {
    name: 'link',
    type: 'url',
    placeholder: props.inputPlaceholder,
    label: __('Issue URL'),
    validationRules: {
      validationRuleUrlAlreadyExists,
    },
    validation: 'validationRuleUrlAlreadyExists|url',
    validationMessages: {
      validationRuleUrlAlreadyExists: __('The issue reference already exists.'),
    },
    required: true,
  },
]

const submitLink = async (data: SubmitData) => {
  const { link } = data

  await props.onSubmit(link)

  return () => closeFlyout(props.name)
}
</script>

<template>
  <CommonFlyout
    :header-icon="icon"
    :header-title="label"
    :name="name"
    no-close-on-action
    :form="form"
    :footer-action-options="{
      actionButton: {
        type: 'submit',
      },
      actionLabel: $t('Link Issue'),
    }"
  >
    <Form
      ref="form"
      :schema="linkSchema"
      should-autofocus
      @submit="submitLink($event as SubmitData)"
    />
  </CommonFlyout>
</template>
