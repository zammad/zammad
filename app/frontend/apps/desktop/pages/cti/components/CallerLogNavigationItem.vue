<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, defineAsyncComponent, useId } from 'vue'
import { useRouter } from 'vue-router'

import { i18n } from '#shared/i18n.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { SidebarName } from '#desktop/components/layout/types.ts'
import { useSidebarDisplay } from '#desktop/components/layout/useSidebarDisplay.ts'
import {
  navigationIconButtonClass,
  navigationItemClass,
  navigationItemHighlightClass,
} from '#desktop/components/PageNavigation/navigationItemClasses.ts'
import type { NavigationItemComponentProps } from '#desktop/components/PageNavigation/types.ts'
import { useCtiSidebar } from '#desktop/entities/cti/composables/useCtiSidebar.ts'

// The route file imports this entry eagerly for the navigation; the list pulls in
//   the user create flyout, which is only worth loading once a call rings.
const CallerLogRingingCalls = defineAsyncComponent(() => import('./CallerLogRingingCalls.vue'))

const props = defineProps<NavigationItemComponentProps>()

const router = useRouter()

const { toggleSidebar } = useSidebarDisplay(SidebarName.Primary)

// Like the old interface: no entry without a CTI backend, while the page itself
//   stays reachable and explains what is missing.
const {
  isIntegrationEnabled,
  unhandledCount,
  ringingCalls,
  isNotificationEnabled,
  setNotificationEnabled,
} = useCtiSidebar()

const hasUnhandledCalls = computed(() => Boolean(unhandledCount.value))

const hasRingingCalls = computed(() => ringingCalls.value.length > 0)

const truncatedCount = computed(() =>
  unhandledCount.value && unhandledCount.value > 99 ? '99+' : unhandledCount.value,
)

// What the number stands for, read as part of the link and button names.
const unhandledCallsLabel = computed(() =>
  i18n.t('%s unhandled calls', String(unhandledCount.value ?? 0)),
)

const openCallerLog = () => router.push(props.route.path)

const titleId = useId()
const countId = useId()
</script>

<template>
  <!-- The ringing calls sit below the entry as their own block, as wide as the entry is. -->
  <div v-if="isIntegrationEnabled" class="flex flex-col" :class="{ grow: !collapsed }">
    <div class="relative flex grow" :class="{ 'justify-center': collapsed }">
      <template v-if="collapsed">
        <CommonButton
          v-tooltip="$t('Phone')"
          :class="navigationIconButtonClass"
          size="large"
          variant="neutral"
          :icon="route.meta.icon"
          :aria-describedby="hasUnhandledCalls ? countId : undefined"
          @click="openCallerLog"
        />
        <CommonBadge
          v-if="hasUnhandledCalls"
          :id="countId"
          class="pointer-events-none absolute top-1 ltr:right-1 rtl:left-1"
          size="dot"
          variant="highlight"
        >
          <span class="sr-only">{{ unhandledCallsLabel }}</span>
        </CommonBadge>
      </template>
      <!--
        The switch is a sibling of the link, laid over its end: interactive content
        must not nest inside an anchor, and this way toggling never navigates.
      -->
      <template v-else>
        <CommonLink
          class="hover:no-underline! focus-visible:rounded-lg! ltr:pr-12 rtl:pl-12"
          :class="[navigationItemClass, { [navigationItemHighlightClass]: active }]"
          :aria-labelledby="hasUnhandledCalls ? `${titleId} ${countId}` : undefined"
          :link="route.path"
          exact-active-class="w-full"
          internal
        >
          <CommonLabel
            :id="titleId"
            class="gap-2 text-sm! text-current!"
            size="medium"
            :prefix-icon="route.meta.icon"
          >
            {{ $t('Phone') }}
          </CommonLabel>
          <CommonBadge
            v-if="hasUnhandledCalls"
            class="min-w-4.5 leading-3.5 font-bold ltr:ml-auto rtl:mr-auto"
            :class="{ 'bg-white! text-blue-800!': active }"
            size="xs"
            variant="highlight"
            rounded
          >
            <span aria-hidden="true">{{ truncatedCount }}</span>
            <span :id="countId" class="sr-only">{{ unhandledCallsLabel }}</span>
          </CommonBadge>
        </CommonLink>
        <FormKit
          type="toggle"
          size="small"
          :label="__('Caller notification')"
          :label-sr-only="true"
          :variants="{ true: 'True', false: 'False' }"
          :model-value="isNotificationEnabled"
          outer-class="absolute top-1/2 -translate-y-1/2 ltr:right-2 rtl:left-2"
          wrapper-class="!px-0 $remove:h-10"
          @input-raw="(value) => setNotificationEnabled(Boolean(value))"
        />
      </template>
    </div>
    <CallerLogRingingCalls
      v-if="hasRingingCalls"
      :calls="ringingCalls"
      :collapsed="collapsed"
      @select="toggleSidebar(false)"
    />
  </div>
</template>
