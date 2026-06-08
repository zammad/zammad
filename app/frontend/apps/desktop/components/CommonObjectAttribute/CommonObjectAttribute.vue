<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'

interface Props {
  label?: string
  body?: string
  attribute?: ObjectAttribute
}

defineProps<Props>()
</script>

<template>
  <div
    class="object-attribute flex flex-col gap-0.5"
    :class="{
      'object-attribute-spanned-column':
        !attribute?.dataOption?.item_class ||
        attribute.dataOption.item_class.indexOf('formGroup--halfSize') === -1,
    }"
    :data-type="attribute?.dataType ? attribute.dataType : undefined"
  >
    <CommonLabel size="small" class="text-stone-200! dark:text-neutral-500!">
      {{ $t(label) }}
    </CommonLabel>

    <CommonLabel tag="div" size="medium" class="break-word text-gray-100! dark:text-neutral-400!">
      <slot>{{ body }}</slot>
    </CommonLabel>
  </div>
</template>
