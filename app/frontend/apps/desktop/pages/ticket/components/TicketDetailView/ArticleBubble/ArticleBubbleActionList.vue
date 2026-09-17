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

// The direct button belongs to articles with a stored translation; the others translate from the
// menu. Translating changes nothing on the ticket, so reading suffices.
const showTranslationToggle = computed(
  () => isTicketAgent.value && articleTranslation.hasDirectTranslationAction(props.article.id),
)

const translateMenuItem = computed<MenuItem | undefined>(() => {
  if (!isTicketAgent.value || !translationStore.isAvailable) return
  if (articleTranslation.hasDirectTranslationAction(props.article.id)) return

  return {
    key: 'translate',
    icon: 'translate',
    label: __('Translate to %s'),
    separatorTop: true,
    labelPlaceholder: [translationStore.targetLocaleName],
    onClick: () => articleTranslation.showTranslation(props.article.id),
  }
})

const isTranslationActive = computed(() => articleTranslation.isTranslationActive(props.article.id))

const isTranslationPending = computed(
  () => articleTranslation.translationFor(props.article.id)?.status === 'pending',
)

// The article keeps its original content while the translation is on its way, so the button carries
// the waiting: it pulses, and offers to stop waiting for it.
const translationToggleLabel = computed(() => {
  if (isTranslationPending.value) return __('Stop translating the article')

  return isTranslationActive.value ? __('Show original') : __('Translate article')
})

// Styled like the menu button next to it (CommonActionMenu's neutral variants); active = blue icon.
const translationToggleClasses = computed(() => {
  const base =
    'outline-offset-0! hover:outline-none! border! border-neutral-100! dark:border-gray-900! dark:hover:border-blue-700! hover:border-blue-800!'

  const color =
    isTranslationActive.value && !isTranslationPending.value
      ? 'text-blue-800! dark:text-blue-800!'
      : 'text-gray-100! dark:text-neutral-400!'

  const background =
    props.position === 'left'
      ? 'bg-neutral-50! hover:bg-white! hover:dark:bg-gray-500! dark:bg-gray-500!'
      : 'bg-blue-100! dark:bg-stone-500!'

  return `${base} ${color} ${background}`
})

const toggleTranslation = () =>
  isTranslationActive.value
    ? articleTranslation.showOriginal(props.article.id)
    : articleTranslation.showTranslation(props.article.id)

const buttonVariantBaseClasses =
  'border! border-neutral-100! outline-transparent! hover:border-blue-700! text-gray-100! dark:border-gray-900! dark:text-neutral-400!'

const buttonVariantClassExtension = computed(() => {
  if (props.position === 'left')
    return `${buttonVariantBaseClasses} hover:border-blue-800! bg-neutral-50! hover:dark:bg-gray-500! hover:bg-white! dark:bg-gray-500!`

  return `${buttonVariantBaseClasses} dark:hover:border-blue-700! bg-blue-100! dark:bg-stone-500!`
})

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

  if (translateMenuItem.value) popoverActions.push(translateMenuItem.value)

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

    <!-- Next to the menu button, on the side of the reply buttons; active = blue icon only, as in the design. -->
    <CommonButton
      v-if="showTranslationToggle"
      v-tooltip="$t(translationToggleLabel)"
      :class="[translationToggleClasses, position === 'right' ? '-order-1' : 'order-1']"
      variant="neutral"
      :aria-pressed="isTranslationActive"
      :aria-busy="isTranslationPending"
      data-test-id="article-translation-toggle"
      :icon-class="`${isTranslationPending ? 'animate-pulse' : ''} size-4! p-0.5`"
      :icon="isTranslationPending ? 'square-fill' : 'translate'"
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
