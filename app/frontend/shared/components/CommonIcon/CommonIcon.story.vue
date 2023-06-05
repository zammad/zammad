<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import '#shared/components/CommonIcon/injectIcons.ts'
import { type Ref, ref, computed } from 'vue'
import CommonIcon from './CommonIcon.vue'
import type { Animations, Sizes } from './types.ts'
import { useIcons } from './useIcons.ts'

const { symbols } = useIcons()

const iconNames = computed(() => symbols.map(([icon]) => icon))

const size: Ref<Sizes | undefined> = ref()
const sizes = ['xs', 'tiny', 'small', 'base', 'medium', 'large']
const fixedSize: Ref<{ width: number; height: number } | undefined> = ref()
const label = ref()
const decorative = ref()
const animation: Ref<Animations | undefined> = ref()
const animations = ['pulse', 'spin', 'ping', 'bounce']
</script>

<template>
  <Story
    title="Icons"
    icon="uil:image"
    group="design-system"
    :layout="{ type: 'grid', width: '100px' }"
  >
    <template #controls>
      <HstSelect v-model="size" :options="sizes" title="Size" />
      <HstJson v-model="fixedSize" title="Fixed Size" />
      <HstText v-model="label" title="Label" />
      <HstCheckbox v-model="decorative" title="Decorative" />
      <HstSelect v-model="animation" :options="animations" title="Animation" />
    </template>

    <Variant
      v-for="iconName of iconNames"
      :id="iconName"
      :key="iconName"
      :title="iconName"
      icon="uil:icons"
      auto-props-disabled
    >
      <CommonIcon
        :size="size"
        :fixed-size="fixedSize"
        :name="iconName"
        :label="label"
        :decorative="decorative"
        :animation="animation"
      />
    </Variant>
  </Story>
</template>
