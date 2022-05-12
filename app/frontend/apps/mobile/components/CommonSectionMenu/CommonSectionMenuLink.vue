<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
export interface Props {
  title?: string
  link?: string
  icon?: string
  // TODO maybe change the name based on the usage
  information?: string
}

defineProps<Props>()
</script>

<template>
  <component
    :is="link ? 'CommonLink' : 'div'"
    :link="link"
    class="cursor-pointer border-b border-gray-300 last:border-0"
    data-test-id="section-menu-link"
  >
    <div
      data-test-id="section-menu-item"
      class="flex items-center justify-between border-b border-gray-300 last:border-0"
    >
      <div class="flex min-h-[54px] items-center">
        <CommonIcon v-if="icon" :name="icon" class="mr-2" />
        <slot>{{ i18n.t(title) }}</slot>
      </div>

      <div class="mr-1 flex items-center">
        <slot name="right">{{ i18n.t(information) }}</slot>
        <CommonIcon
          name="arrow-right"
          class="ml-2 text-gray-300"
          :fixed-size="{ width: 12, height: 12 }"
        />
      </div>
    </div>
  </component>
</template>
