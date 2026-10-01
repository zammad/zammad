<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onUnmounted, ref } from 'vue'

import { useTicketArticleReplyAction } from '#shared/entities/ticket/composables/useTicketArticleReplyAction.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { getTicketView } from '#shared/entities/ticket/utils/getTicketView.ts'
import { createArticleActions } from '#shared/entities/ticket-article/action/plugins/index.ts'
import { getArticleSelection } from '#shared/entities/ticket-article/composables/getArticleSelection.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import log from '#shared/utils/log.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

const props = defineProps<{
  position: 'left' | 'right'
  article: TicketArticle
}>()

const { ticket, showTicketArticleReplyForm, form, articleTranslation } = useTicketInformation()

const translationStore = useArticleTranslationStore()

const isTicketAgent = computed(() => !!ticket.value && getTicketView(ticket.value).isTicketAgent)

// Translating changes nothing on the ticket, so reading suffices.
const showTranslationToggle = computed(() => isTicketAgent.value && translationStore.isAvailable)

const isTranslationActive = computed(() => articleTranslation.isTranslationActive(props.article.id))

// A regenerated translation is on its way just the same, while the current one stays shown.
const isTranslationPending = computed(() => {
  const translation = articleTranslation.translationFor(props.article.id)

  return (
    translation?.status === 'pending' ||
    (translation?.status === 'done' && !!translation.regenerating)
  )
})

const isTranslationFailed = computed(
  () => articleTranslation.translationFor(props.article.id)?.status === 'error',
)

// One control in all states, always named by its action: the article body names a running
// translation and the failure. A running translation cannot be stopped, aria-busy says so.
const translationToggleLabel = computed(() => {
  if (isTranslationPending.value) return __('Translate article')
  if (isTranslationFailed.value) return __('Dismiss alert')

  return isTranslationActive.value ? __('Show original') : __('Translate article')
})

// Styled like the menu button next to it (CommonActionMenu's neutral variants); active = blue icon.
const translationToggleClasses = computed(() => {
  const base = 'outline-offset-0! hover:outline-none! border!'

  const border = isTranslationFailed.value
    ? 'border-red-500! dark:border-red-500!'
    : 'border-neutral-100! dark:border-gray-900!'

  const hover = isTranslationPending.value
    ? 'cursor-default'
    : 'dark:hover:border-blue-700! hover:border-blue-800!'

  const color = (() => {
    if (isTranslationPending.value) return 'text-[#8E9299]! dark:text-[#8E9299]!'
    if (isTranslationFailed.value) return 'text-red-500! dark:text-red-500!'
    if (isTranslationActive.value) return 'text-blue-800! dark:text-blue-800!'

    return 'text-normal!'
  })()

  const background =
    props.position === 'left'
      ? 'bg-neutral-50! hover:bg-white! hover:dark:bg-gray-500! dark:bg-gray-500!'
      : 'bg-blue-100! dark:bg-stone-500!'

  return `${base} ${border} ${hover} ${color} ${background}`
})

// A failure is put away like a translation; the menu asks again.
const toggleTranslation = () => {
  if (isTranslationPending.value) return

  if (isTranslationActive.value || isTranslationFailed.value)
    articleTranslation.showOriginal(props.article.id)
  else articleTranslation.showTranslation(props.article.id)
}

const buttonVariantBaseClasses =
  'border! border-neutral-100! outline-transparent! hover:border-blue-700! text-normal! dark:border-gray-900!'

const buttonVariantClassExtension = computed(() =>
  props.position === 'left'
    ? `${buttonVariantBaseClasses} hover:border-blue-800! bg-neutral-50! hover:dark:bg-gray-500! hover:bg-white! dark:bg-gray-500!`
    : `${buttonVariantBaseClasses} dark:hover:border-blue-700! bg-blue-100! dark:bg-stone-500!`,
)

const { getNewArticleBody, openReplyForm } = useTicketArticleReplyAction(
  form,
  showTicketArticleReplyForm,
)

const disposeCallbacks: (() => unknown)[] = []

const onDispose = (callback: () => unknown) => {
  disposeCallbacks.push(callback)
}

const handleDisposeCallbacks = () => {
  disposeCallbacks.forEach((callback) => callback())
  disposeCallbacks.length = 0
}

onUnmounted(handleDisposeCallbacks)

const recalculateTriggerId = ref(0)

const articleSelection = (articleInternalId: number) => {
  try {
    // Can throw RangeError.
    return getArticleSelection(articleInternalId)
  } catch (err) {
    log.error('[Article Quote] Failed to parse article selection', err)
    return undefined
  }
}

const actions = computed(() => {
  // Recalculation trigger ID cannot be less than 0, so it's just a hint for Vue to recalculate this computed property.
  if (!ticket.value || recalculateTriggerId.value < 0)
    return {
      popoverActions: [],
      alwaysVisibleActions: [],
    }

  // Clear all side effects before recalculating actions.
  handleDisposeCallbacks()

  const articleActions = createArticleActions(ticket.value, props.article, 'desktop', {
    onDispose,
    recalculate: () => {
      recalculateTriggerId.value += 1
    },
  })

  const popoverActions: MenuItem[] = []
  const alwaysVisibleActions: MenuItem[] = []

  articleActions.forEach((action) => {
    const mappedAction = {
      key: action.name,
      label: action.label,
      icon: action.icon,
      link: action.link,
      ...(action.perform
        ? {
            onClick: () => {
              if (!ticket.value) return

              action.perform!(ticket.value, props.article, {
                formId: form.value?.formId ?? '',
                selection: articleSelection(props.article.internalId),
                openReplyForm,
                getNewArticleBody,
              })
            },
          }
        : {}),
    }

    if (action.alwaysVisible) {
      alwaysVisibleActions.push(mappedAction)
    } else {
      popoverActions.push(mappedAction)
    }
  })

  return {
    alwaysVisibleActions,
    popoverActions,
  }
})
</script>

<template>
  <!-- Rendered for read-only tickets as well: the plugin filter keeps the write actions out. -->
  <div
    v-if="
      actions.alwaysVisibleActions.length || actions.popoverActions.length || showTranslationToggle
    "
    class="absolute inset-e-3 bottom-0 flex w-fit translate-y-1/2 items-center gap-1 print:hidden"
    :class="{ 'inset-s-3': position === 'left' }"
  >
    <div
      v-for="action in actions.alwaysVisibleActions"
      :key="action.key"
      data-test-id="top-level-article-action-container"
      class="order-1 flex items-center"
      :class="position === 'right' ? 'order-first' : 'order-last'"
    >
      <CommonButton
        class="px-1 py-0.5! text-xs! focus-visible:outline-offset-0! focus-visible:outline-blue-800!"
        :class="buttonVariantClassExtension"
        :prefix-icon="action.icon"
        size="large"
        @click="action.onClick"
        >{{ $t(action.label) }}
      </CommonButton>
    </div>

    <!-- Next to the menu button, on the side of the reply buttons; active = blue icon only, as in the design.
      Not `disabled` while busy: that takes the pointer events, and with them the tooltip naming it. -->
    <CommonButton
      v-if="showTranslationToggle"
      v-tooltip="$t(translationToggleLabel)"
      :class="[translationToggleClasses, position === 'right' ? '-order-1' : 'order-1']"
      variant="neutral"
      :aria-pressed="isTranslationActive && !isTranslationPending"
      :aria-busy="isTranslationPending"
      :aria-disabled="isTranslationPending || undefined"
      data-test-id="article-translation-toggle"
      icon-class="size-4! p-0.5"
      icon="translate"
      size="medium"
      @click="toggleTranslation"
    />

    <CommonActionMenu
      class="flex!"
      :entity="{ ticket, article }"
      button-size="medium"
      :placement="position === 'left' ? 'arrowStart' : 'arrowEnd'"
      :default-button-variant="position === 'left' ? 'neutral-dark' : 'neutral-light'"
      :actions="actions.popoverActions"
      no-single-action-mode
      z-index="20"
    />
  </div>
</template>
