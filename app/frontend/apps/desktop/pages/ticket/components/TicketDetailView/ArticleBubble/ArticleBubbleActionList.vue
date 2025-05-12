<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { useTicketArticleReplyAction } from '#shared/entities/ticket/composables/useTicketArticleReplyAction.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { createArticleActions } from '#shared/entities/ticket-article/action/plugins/index.ts'
import { getArticleSelection } from '#shared/entities/ticket-article/composables/getArticleSelection.ts'
import log from '#shared/utils/log.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

const props = defineProps<{
  position: 'left' | 'right'
  article: TicketArticle
}>()

const { ticket, isTicketEditable, showTicketArticleReplyForm, form } =
  useTicketInformation()

const { isTouchDevice } = useTouchDevice()

const buttonVariantClassExtension = computed(() => {
  // TODO maybe general classes string for same classes
  if (props.position === 'left')
    return 'border! border-neutral-100! outline-transparent! hover:border-blue-700! hover:border-blue-800! bg-neutral-50! hover:dark:bg-gray-500! hover:bg-white!  text-gray-100! dark:border-gray-900! dark:bg-gray-500! dark:text-neutral-400!'

  return 'border! border-neutral-100! outline-transparent! hover:border-blue-700! dark:hover:border-blue-700! bg-blue-100! bg-blue-100!  text-gray-100! dark:border-gray-900! dark:bg-stone-500! dark:text-neutral-400!'
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
  if (!ticket.value || recalculateTriggerId.value < 0) {
    return {
      popoverActions: [],
      alwaysVisibleActions: [],
    }
  }

  // Clear all side effects before recalculating actions.
  handleDisposeCallbacks()

  const articleActions = createArticleActions(
    ticket.value,
    props.article,
    'desktop',
    {
      onDispose,
      recalculate: () => {
        recalculateTriggerId.value += 1
      },
    },
  )

  const popoverActions: MenuItem[] = []
  const alwaysVisibleActions: MenuItem[] = []

  articleActions.forEach((action) => {
    const mappedAction = {
      key: action.name,
      label: action.label,
      icon: action.icon,
      link: action.link,
      ...(action?.perform
        ? {
            onClick: () => {
              if (!action?.perform || !ticket.value) return

              action.perform(ticket.value, props.article, {
                formId: form.value?.formId || '',
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
  <div
    v-if="isTicketEditable"
    class="absolute bottom-0 flex w-fit translate-y-1/2 items-center gap-1 ltr:right-3 rtl:left-3"
    :class="{ 'ltr:left-3 rtl:right-3': position === 'left' }"
  >
    <div
      v-for="action in actions.alwaysVisibleActions"
      :key="action.key"
      data-test-id="top-level-article-action-container"
      class="order-1 flex items-center"
      :class="{
        '-order-1!': position === 'right',
        'opacity-0 transition-opacity group-hover/article:opacity-100 focus-within:opacity-100':
          !isTouchDevice,
      }"
    >
      <CommonButton
        class="px-1 py-0.5! text-xs! focus-visible:outline-offset-0! focus-visible:outline-blue-800!"
        :class="[buttonVariantClassExtension]"
        :prefix-icon="action.icon"
        size="large"
        @click="action.onClick"
        >{{ $t(action.label) }}
      </CommonButton>
    </div>

    <CommonActionMenu
      class="flex!"
      :entity="{ ticket, article }"
      button-size="medium"
      :placement="position === 'left' ? 'arrowStart' : 'arrowEnd'"
      :default-button-variant="
        position === 'left' ? 'neutral-dark' : 'neutral-light'
      "
      :actions="actions.popoverActions"
      no-single-action-mode
    />
  </div>
</template>
