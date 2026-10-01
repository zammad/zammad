<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  label: string
  values?: string[]
}

defineProps<Props>()
</script>

<template>
  <div class="flex flex-col gap-0.5">
    <CommonLabel size="small" class="block text-muted!">
      {{ label }}
    </CommonLabel>
    <slot>
      <template v-if="values">
        <div role="list" class="flex flex-wrap gap-0.5">
          <CommonLabel
            v-for="(value, index) in values"
            :key="value"
            role="listitem"
            class="text-normal"
          >
            {{ `${value}${index < values.length - 1 ? ',' : ''}` }}
          </CommonLabel>
        </div>
      </template>
    </slot>
  </div>
</template>
