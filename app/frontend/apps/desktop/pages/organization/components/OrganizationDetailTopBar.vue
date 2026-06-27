<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementSize } from '@vueuse/core'
import { computed, toRef, useTemplateRef, type Ref } from 'vue'
import { useRouter } from 'vue-router'

import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'
import { useReducedMotion } from '#shared/composables/useReducedMotion.ts'
import type { Organization } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useStickyTopCalculator } from '#desktop/components/Form/fields/FieldEditor/useStickyTopCalculator.ts'
import OrganizationInfo from '#desktop/components/Organization/OrganizationInfo.vue'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import { useTopBarHeaderHover } from '#desktop/composables/useTopBarHeaderHover.ts'

import { initializeActionPlugins } from './OrganizationDetailTopBar/actions/index.ts'

interface Props {
  organization: Organization
  organizationDisplayName: string
  contentContainerElement: HTMLElement | null
}

const props = defineProps<Props>()

const breadcrumbItems = computed(() => [
  // TODO: Adjust breadcrumbs when the navigational mechanism is in place.
  {
    label: __('Organization'),
  },
  {
    label: props.organizationDisplayName,
    noOptionLabelTranslation: true,
  },
])

const { copyToClipboard } = useCopyToClipboard()

const config = toRef(useApplicationStore(), 'config')

const copyOrganizationDisplayNameToClipboard = () => {
  copyToClipboard([
    new ClipboardItem({
      'text/plain': props.organizationDisplayName,
      'text/html': `<a href="${config.value.http_type}://${config.value.fqdn}/desktop/organizations/${props.organization.internalId}">${props.organizationDisplayName}</a>`,
    }),
  ])
}

const { y } = useElementScroll(toRef(props, 'contentContainerElement') as Ref<HTMLDivElement>)
const { width } = useElementSize(toRef(props, 'contentContainerElement'))

const headerWithDetailsElement = useTemplateRef('header-with-details')
const headerWithHiddenDetailsElement = useTemplateRef('header-with-hidden-details')

const { height: headerWithDetailsHeight } = useElementSize(headerWithDetailsElement, undefined, {
  box: 'border-box',
})

const { height: headerWithHiddenDetailsHeight } = useElementSize(
  headerWithHiddenDetailsElement,
  undefined,
  {
    box: 'border-box',
  },
)

const { containerEventHandlers, isHovering } = useTopBarHeaderHover([headerWithDetailsElement])

const containerWidth = computed(() => (width.value ? `${width.value}px` : 'auto'))

// Show the header earlier to always have it visible
const NEGATIVE_PADDING = -30

const absoluteContainerOffset = computed(() => {
  const offset = y.value - (headerWithDetailsHeight.value + NEGATIVE_PADDING)
  return `${offset > 0 ? 0 : offset}px`
})

const stickyContainerTop = computed(() => {
  if (isHovering.value) return '0px'
  if (y.value < headerWithDetailsHeight.value) return `-${y.value}px`
  return `-${headerWithDetailsHeight.value}px`
})

const { topLevelActions, secondLevelActions } = initializeActionPlugins()

const { hasPermission } = useSessionStore()

const allowedTopLevelActions = computed(() =>
  topLevelActions.filter(
    (item) =>
      (item.permission ? hasPermission(item.permission) : true) &&
      (item.show ? item.show(props.organization) : true),
  ),
)

const router = useRouter()

const currentVisibleHeaderHeight = computed(() => {
  return isHovering.value ? headerWithDetailsHeight.value : headerWithHiddenDetailsHeight.value
})

// 7px is needed to compensate some overlap
useStickyTopCalculator(currentVisibleHeaderHeight, { offset: 7 })

const { hasReducedMotion } = useReducedMotion()
</script>

<template>
  <header
    ref="header-with-hidden-details"
    class="absolute top-0 right-0 left-0 z-30 w-full border-b border-neutral-100 bg-neutral-50/80 p-2 backdrop-blur-2xs dark:border-gray-900 dark:bg-gray-500/80"
    :class="{ '-z-10! opacity-0': isHovering }"
    :style="{
      transform: `translateY(${absoluteContainerOffset})`,
      width: containerWidth,
    }"
    aria-hidden="true"
    v-on="containerEventHandlers"
  >
    <div class="mx-auto flex size-full max-w-266">
      <OrganizationInfo :organization="organization" size="small" title-size="large" no-link />
    </div>
  </header>
  <header
    ref="header-with-details"
    data-test-id="organization-detail-top-bar"
    class="sticky z-20 border-b border-neutral-100 bg-neutral-50/80 px-5.5 py-3 backdrop-blur-2xs dark:border-gray-900 dark:bg-gray-500/80"
    :class="{
      'transition-[top]': isHovering && !hasReducedMotion,
    }"
    :style="{
      top: stickyContainerTop,
    }"
    v-on="containerEventHandlers"
  >
    <!-- h-6 because of ticket detail view has action which add a additional height to the breadcrumbs -->
    <CommonBreadcrumb class="flex h-6" :items="breadcrumbItems" size="small" emphasize-last-item>
      <template #trailing>
        <CommonButton
          v-if="organizationDisplayName"
          v-tooltip="$t('Copy organization display name')"
          variant="secondary"
          icon="files"
          size="small"
          class="ms-1"
          @click="copyOrganizationDisplayNameToClipboard"
        />
      </template>
    </CommonBreadcrumb>
    <div class="mx-auto mt-3 flex w-full max-w-278">
      <OrganizationInfo
        :organization="organization"
        responsive
        size="normal"
        title-size="xl"
        title-class="font-medium"
        no-link
      >
        <template #actions>
          <div role="toolbar" class="flex items-center gap-1.5 ltr:ml-auto rtl:mr-auto">
            <CommonButton
              v-for="action in allowedTopLevelActions"
              :key="action.key"
              class="aspect-square w-auto! rounded-lg! px-2! outline-offset-0! @3xl:aspect-auto @3xl:rounded-md! @3xl:px-2.5! @3xl:py-1.5!"
              no-truncate
              :prefix-icon="action.icon"
              @click="action?.onClick?.(organization, router)"
            >
              <span class="sr-only shrink-0 text-xs! @3xl:not-sr-only">
                {{ $t(action.label) }}
              </span>
            </CommonButton>
            <CommonActionMenu
              button-size="medium"
              role="presentation"
              class="flex! h-full items-center"
              :custom-menu-button-label="$t('Additional actions')"
              :entity="organization"
              no-single-action-mode
              :actions="secondLevelActions"
            />
          </div>
        </template>
      </OrganizationInfo>
    </div>
  </header>
</template>
