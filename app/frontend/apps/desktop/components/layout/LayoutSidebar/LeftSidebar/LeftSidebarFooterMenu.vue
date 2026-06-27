<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'

import { useBetaUi } from '#desktop/components/BetaUi/composables/useBetaUi.ts'
import { showFeedbackConsent } from '#desktop/components/BetaUi/composables/useBetaUiFeedbackConsent.ts'
import { useFeedbackDialog } from '#desktop/components/BetaUi/FeedbackDialog/useFeedbackDialog.ts'
import CollapseButton from '#desktop/components/CollapseButton/CollapseButton.vue'
import AvatarMenu from '#desktop/components/layout/LayoutSidebar/LeftSidebar/AvatarMenu/AvatarMenu.vue'
import MenuContainer from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/MenuContainer.vue'
import { useSidebarDisplay } from '#desktop/components/layout/useSidebarDisplay.ts'

import { SidebarName } from '../../types.ts'

const { isSidebarCollapsed, toggleSidebar } = useSidebarDisplay(SidebarName.Primary)

const {
  switchValue,
  toggleBetaUiSwitch,
  betaUiSwitchEnabled,
  dismissBetaUiSwitch,
  hasFeedbackConsent,
} = useBetaUi()

const { openFeedbackDialog } = useFeedbackDialog()

const { isTouchDevice } = useTouchDevice()
</script>

<template>
  <section
    class="flex items-center justify-center"
    :class="{ 'mx-auto mb-2 flex-col!': isSidebarCollapsed }"
  >
    <div class="flex w-full flex-col gap-2">
      <div
        v-if="betaUiSwitchEnabled && !isSidebarCollapsed"
        class="relative -mx-3 inline-flex h-11 items-center justify-start gap-2 bg-blue-900 ps-3 pe-8 dark:bg-blue-900"
      >
        <FormKit
          type="toggle"
          :label="__('BETA UI')"
          :value="true"
          :variants="{ true: 'True', false: 'False' }"
          wrapper-class="!flex-row"
          label-class="!text-white truncate"
          @input-raw="toggleBetaUiSwitch()"
        />
        <CommonLink
          v-if="switchValue"
          class="truncate text-white hover:text-white! hover:underline!"
          link="#"
          size="small"
          @click="
            () => (hasFeedbackConsent === 'true' ? openFeedbackDialog() : showFeedbackConsent())
          "
        >
          {{ $t('Feedback') }}
        </CommonLink>
        <CommonIcon
          class="absolute inset-e-3 text-white"
          name="x"
          :fixed-size="{ width: 16, height: 16 }"
          role="button"
          :aria-label="$t('Hide BETA UI switch')"
          @click="dismissBetaUiSwitch"
        />
      </div>

      <div class="flex gap-2" :class="{ 'mx-auto mb-0.5 flex-col!': isSidebarCollapsed }">
        <CollapseButton
          owner-id="primary-sidebar"
          no-padded
          visible
          size="large"
          variant="tertiary-gray"
          :collapsed="isSidebarCollapsed"
          :class="[
            isSidebarCollapsed ? 'order-last' : 'order-first',
            { 'lg:hidden': !isTouchDevice },
          ]"
          :collapse-label="$t('Collapse sidebar')"
          :expand-label="$t('Expand sidebar')"
          @toggle-collapse="toggleSidebar"
        />

        <div
          class="flex items-center justify-start"
          :class="{ 'justify-center!': isSidebarCollapsed }"
        >
          <AvatarMenu />
        </div>

        <div
          class="flex flex-1 items-center justify-end"
          :class="{ 'justify-center!': isSidebarCollapsed }"
        >
          <MenuContainer />
        </div>
      </div>
    </div>
  </section>
</template>
