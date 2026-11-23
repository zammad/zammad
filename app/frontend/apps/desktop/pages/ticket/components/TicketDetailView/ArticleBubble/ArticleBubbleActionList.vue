<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onUnmounted, ref } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useTicketArticleReplyAction } from '#shared/entities/ticket/composables/useTicketArticleReplyAction.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { getTicketView } from '#shared/entities/ticket/utils/getTicketView.ts'
import { createArticleActions } from '#shared/entities/ticket-article/action/plugins/index.ts'
import { getArticleSelection } from '#shared/entities/ticket-article/composables/getArticleSelection.ts'
import { usePendingArticleAction } from '#shared/entities/ticket-article/composables/usePendingArticleAction/usePendingArticleAction.ts'
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

// The article body names a running translation and a failure, and offers the retry for the latter.
// A running translation cannot be stopped, aria-busy says so.
const isTranslationToggleDisabled = computed(
  () => isTranslationPending.value || isTranslationFailed.value,
)

// One control in all states, always named by its action.
const translationToggleLabel = computed(() =>
  isTranslationActive.value && !isTranslationToggleDisabled.value
    ? __('Show original')
    : __('Translate article'),
)

// Styled like the menu button next to it (CommonActionMenu's neutral variants); active = blue icon.
const translationToggleClasses = computed(() => {
  const base =
    'outline-offset-0! hover:outline-none! border! border-neutral-100! dark:border-gray-900!'

  const hover = isTranslationToggleDisabled.value
    ? 'cursor-default'
    : 'dark:hover:border-blue-700! hover:border-blue-800!'

  const color = (() => {
    if (isTranslationToggleDisabled.value) return 'text-normal/50!'
    if (isTranslationActive.value) return 'text-blue-800! dark:text-blue-800!'

    return 'text-normal!'
  })()

  const background =
    props.position === 'left'
      ? 'bg-neutral-50! hover:bg-white! hover:dark:bg-gray-500! dark:bg-gray-500!'
      : 'bg-blue-100! dark:bg-stone-500!'

  return `${base} ${hover} ${color} ${background}`
})

const toggleTranslation = () => {
  if (isTranslationToggleDisabled.value) return

  if (isTranslationActive.value) articleTranslation.showOriginal(props.article.id)
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

const { isPending, isActionPending, performAction } = usePendingArticleAction()

const { notify } = useNotifications()

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
      separatorTop: action.separatorTop,
      ...(action.perform
        ? {
            onClick: () => {
              if (!ticket.value) return

              const selection = articleSelection(props.article.internalId)

              // A translation takes the place of the original in the article body, so a quote of
              //   it would read as if the customer had written it.
              const isQuoteRefused =
                !!(selection?.html || selection?.text) &&
                articleTranslation.isTranslationDisplayed(props.article.id)

              if (isQuoteRefused && action.quotesSelection)
                notify({
                  id: 'article-translation-quote-refused',
                  type: NotificationTypes.Warn,
                  message: __('Translated text cannot be quoted. Show the original to quote it.'),
                })

              performAction(action, ticket.value, props.article, {
                formId: form.value?.formId ?? '',
                selection: isQuoteRefused ? undefined : selection,
                openReplyForm: (values) =>
                  openReplyForm({ ...values, answeredArticleId: props.article.id }),
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
        :disabled="isPending"
        :aria-busy="isActionPending(action.key, article.id)"
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
      :aria-pressed="isTranslationActive && !isTranslationToggleDisabled"
      :aria-busy="isTranslationPending"
      :aria-disabled="isTranslationToggleDisabled || undefined"
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
      :disabled="isPending"
      :actions="actions.popoverActions"
      no-single-action-mode
      z-index="20"
    />
  </div>
</template>
