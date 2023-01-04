<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, type HTMLAttributes } from 'vue'
import { type Props as IconProps } from '@shared/components/CommonIcon/CommonIcon.vue'
import { useLocaleStore } from '@shared/stores/locale'

export interface Props {
  label?: string
  labelPlaceholder?: string[]
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
    :is="link ? 'CommonLink' : 'button'"
    :link="link"
    class="cursor-pointer border-b border-white/10 last:border-0"
    data-test-id="section-menu-link"
  >
    <div
      data-test-id="section-menu-item"
      class="flex items-center justify-between"
    >
      <div class="flex min-h-[54px] items-center">
        <div
          v-if="iconProps || $slots.icon"
          class="flex h-8 w-8 items-center justify-center ltr:mr-2 rtl:ml-2"
          data-test-id="wrapper-icon"
          :class="{
            [`rounded-lg ${iconBg}`]: iconBg,
          }"
        >
          <slot name="icon">
            <CommonIcon
              v-if="iconProps"
              v-bind="iconProps"
              size="base"
              decorative
            />
          </slot>
        </div>
        <slot>{{ i18n.t(label, ...(labelPlaceholder || [])) }}</slot>
      </div>

      <div
        class="mr-1 flex items-center"
        data-test-id="section-menu-information"
      >
        <slot name="right">{{ information && i18n.t(`${information}`) }}</slot>
        <CommonIcon
          class="text-gray ltr:ml-2 rtl:mr-2"
          :name="`mobile-chevron-${
            locale.localeData?.dir === 'rtl' ? 'left' : 'right'
          }`"
          size="base"
          decorative
        />
      </div>
    </div>
  </component>
</template>
