<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef } from 'vue'

import { isInlineAttributeEditable } from '#shared/components/EntityAttributes/utils.ts'

import type { EntityAttributeProps } from '../../types.ts'
import type { EntityAttributeRichtext } from './attributeRichtextTypes.ts'
import type { FormKitNode } from '@formkit/core'

const props = defineProps<EntityAttributeProps<EntityAttributeRichtext, string>>()

const nodeElement = useTemplateRef<{ node: FormKitNode }>('input')

const handleReset = () => nodeElement.value?.node.reset()

const enableInlineEdit = computed(
  () =>
    props.mode === 'view' && isInlineAttributeEditable(props.attribute.name, props.inlineEditable),
)
</script>

<template>
  <FormKit
    v-if="enableInlineEdit"
    :id="attribute.id"
    ref="input"
    :model-value="value"
    :name="attribute.display"
    :classes="{
      outer: 'w-full',
      inner: 'dark:bg-transparent bg-transparent outline-0!',
      input: 'min-h-7!',
    }"
    type="editor"
    :meta="{
      footer: {
        maxlength: props.attribute?.dataOption?.maxlength,
        disabled: true,
      },
    }"
    :label-sr-only="true"
    :label="attribute.display"
    :reset="handleReset"
    :inline="true"
    extension-set="basic"
  />
  <!-- eslint-disable vue/no-v-html -->
  <div v-else v-html="value" />
</template>
