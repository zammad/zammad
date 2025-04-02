<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->
<script lang="ts" setup>
interface Props {
  title: string
  text?: string
  icon?: string
  withIllustration?: boolean
}

defineProps<Props>()
</script>
<template>
  <div
    class="absolute top-1/2 w-full -translate-y-1/2 text-center ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2"
  >
    <img
      v-if="withIllustration"
      class="mx-auto"
      src="./assets/confetti.svg"
      alt="confetti"
    />
    <CommonLabel
      tag="h2"
      size="xl"
      class="flex items-center justify-center gap-2 text-black dark:text-white"
    >
      <!--   prefix-icon prop can not be used without changing the size regarding the icon   -->
      <CommonIcon v-if="icon" size="small" :name="icon" />
      <span>
        {{ title }}
      </span>
    </CommonLabel>

    <slot>
      <CommonLabel tag="p" class="block! py-5">
        {{ text }}
      </CommonLabel>
    </slot>
  </div>
</template>
