<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, type HTMLAttributes } from 'vue'
import { type Props as IconProps } from '@shared/components/CommonIcon/CommonIcon.vue'
import useLocaleStore from '@shared/stores/locale'

export interface Props {
  label?: string
  link?: string
  icon?: string | (IconProps & HTMLAttributes)
  iconBg?: string
  // TODO maybe change the name based on the usage
  information?: string | number
}

const props = defineProps<Props>()

const locale = useLocaleStore()

const iconProps = computed<IconProps | null>(() => {
  if (!props.icon) return null

  if (typeof props.icon === 'string') {
    return { name: props.icon }
  }

  return props.icon
})
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
        <div
          v-if="iconProps"
          class="flex h-8 w-8 items-center justify-center ltr:mr-2 rtl:ml-2"
          data-test-id="wrapper-icon"
          :class="{
            [`rounded-lg ${iconBg}`]: iconBg,
          }"
        >
          <CommonIcon v-bind="iconProps" />
        </div>
        <slot>{{ i18n.t(label) }}</slot>
      </div>

      <div
        class="mr-1 flex items-center"
        data-test-id="section-menu-information"
      >
        <slot name="right">{{ information && i18n.t(`${information}`) }}</slot>
        <CommonIcon
          class="text-gray-300 ltr:ml-2 rtl:mr-2"
          :name="`arrow-${locale.localeData?.dir === 'rtl' ? 'left' : 'right'}`"
          :fixed-size="{ width: 12, height: 12 }"
        />
      </div>
    </div>
  </component>
</template>
