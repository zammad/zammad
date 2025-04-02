<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'
import { computed, provide } from 'vue'

import AvatarMenu from '#desktop/components/layout/LayoutSidebar/LeftSidebar/AvatarMenu/AvatarMenu.vue'
import MenuContainer from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/MenuContainer.vue'
import { COLLAPSED_STATE_KEY } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/useCollapsedState.ts'
import { useNewBetaUi } from '#desktop/composables/useNewBetaUi.ts'

const props = defineProps<{
  collapsed?: boolean
}>()

provide(
  COLLAPSED_STATE_KEY,
  computed(() => props.collapsed),
)

const { betaUiSwitchEnabled, toggleBetaUiSwitch, dismissBetaUiSwitch } =
  useNewBetaUi()
</script>

<template>
  <section
    class="flex items-center justify-center"
    :class="{ 'mx-auto mb-0.5 flex-col!': collapsed }"
  >
    <div class="flex w-full flex-col gap-2">
      <div
        v-if="betaUiSwitchEnabled && !collapsed"
        class="relative -mx-3 inline-flex h-11 items-center justify-start gap-2 bg-blue-900 ps-3 pe-8 dark:bg-blue-900"
      >
        <FormKit
          type="toggle"
          :label="__('New Beta UI')"
          :value="true"
          :variants="{ true: 'True', false: 'False' }"
          wrapper-class="!flex-row"
          label-class="!text-white truncate"
          @input-raw="toggleBetaUiSwitch()"
        />
        <!-- <CommonLink class="truncate text-white" link="#" size="small">
          {{ $t('Send Feedback') }}
        </CommonLink> -->
        <CommonIcon
          class="absolute end-3 text-white"
          name="x"
          :fixed-size="{ width: 16, height: 16 }"
          role="button"
          :aria-label="$t('Hide Beta UI switch')"
          @click="dismissBetaUiSwitch"
        />
      </div>

      <div class="flex" :class="{ 'mx-auto mb-0.5 flex-col!': collapsed }">
        <div
          class="flex items-center justify-start"
          :class="{ 'justify-center!': collapsed }"
        >
          <AvatarMenu />
        </div>

        <div
          class="flex flex-1 items-center justify-end"
          :class="{ 'justify-center!': collapsed }"
        >
          <MenuContainer />
        </div>
      </div>
    </div>
  </section>
</template>
