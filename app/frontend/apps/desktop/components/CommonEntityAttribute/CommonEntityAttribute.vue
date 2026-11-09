<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { EntityAttribute } from '#shared/entities/core/attributes/types/store.ts'

interface Props {
  label?: string
  body?: string
  attribute?: EntityAttribute
}

defineProps<Props>()
</script>

<template>
  <div
    class="entity-attribute flex flex-col gap-0.5"
    :class="{
      'entity-attribute-spanned-column':
        !attribute?.dataOption?.item_class ||
        attribute.dataOption.item_class.indexOf('formGroup--halfSize') === -1,
    }"
    :data-type="attribute?.dataType ? attribute.dataType : undefined"
  >
    <CommonLabel size="small" class="text-muted!">
      {{ $t(label) }}
    </CommonLabel>

    <CommonLabel tag="div" size="medium" class="break-word text-normal!">
      <slot>{{ body }}</slot>
    </CommonLabel>
  </div>
</template>
