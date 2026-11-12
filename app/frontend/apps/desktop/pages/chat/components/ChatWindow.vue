<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, ref, useTemplateRef, watch } from 'vue'
import { useRouter } from 'vue-router'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { i18n } from '#shared/i18n.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { useChatAgentName } from '#desktop/entities/chat/composables/useChatAgentName.ts'
import { useChatConversation } from '#desktop/entities/chat/composables/useChatConversation.ts'
import { useChatAgentStore } from '#desktop/entities/chat/stores/chatAgent.ts'
import { useChatPreferencesStore } from '#desktop/entities/chat/stores/chatPreferences.ts'
import { useChatUnreadMessagesStore } from '#desktop/entities/chat/stores/chatUnreadMessages.ts'
import { chatTicketCreateRoute } from '#desktop/entities/chat/utils.ts'

import ChatComposer from './ChatComposer.vue'
import ChatConnectionLine from './ChatConnectionLine.vue'
import ChatFooterNote from './ChatFooterNote.vue'
import ChatThread from './ChatThread.vue'
import ChatTicketCreateButton from './ChatTicketCreateButton.vue'
import ChatWindowDetails from './ChatWindowDetails.vue'
import ChatWindowHeader from './ChatWindowHeader.vue'

import type { ChatFooterNote as ChatFooterNoteData, ChatWindowDetail } from './types.ts'

interface Props {
  sessionId: string
}

const props = defineProps<Props>()

defineEmits<{
  close: []
}>()

const windowElement = useTemplateRef('window')

const composer = useTemplateRef('composer')

// A notification can bring the agent here before the conversation loaded, so before the composer is there.
const isFocusPending = ref(false)

const focusComposer = () => {
  if (composer.value) {
    composer.value.focus()
    return
  }

  isFocusPending.value = true
}

watch(composer, (element) => {
  if (!element || !isFocusPending.value) return

  isFocusPending.value = false
  element.focus()
})

const {
  session,
  name,
  title,
  isLoading,
  loadError,
  reload,
  entries,
  ending,
  isClosed,
  isTransferred,
  isOwnSession,
  isWaiting,
  handlingAgent,
  canWrite,
  canEnd,
  isCustomerTyping,
  isEnding,
  sendMessage,
  sendTyping,
  end,
  rename,
  transfer,
} = useChatConversation(() => props.sessionId, {
  windowElement,
  inputElement: () => composer.value?.input,
  focusWindow: focusComposer,
})

const { topics } = storeToRefs(useChatAgentStore())

const { unreadMessageIds } = storeToRefs(useChatUnreadMessagesStore())

// The handler already told the agent that something went wrong; the window says what it means for it.
const loadErrorNote = computed(() =>
  loadError.value ? __('The conversation could not be loaded.') : undefined,
)

const openDetail = ref<ChatWindowDetail>()

const header = useTemplateRef('header')

const details = useTemplateRef('details')

// The buttons that close the details go with them: the focus goes back to the menu that opened them.
const closeDetail = () => {
  if (details.value?.$el?.contains?.(document.activeElement)) header.value?.focusActions()

  openDetail.value = undefined
}

const { hasTicketCreateAccess } = storeToRefs(useChatPreferencesStore())

const router = useRouter()

const actions: MenuItem[] = [
  {
    key: 'ticket',
    label: __('Turn chat into a ticket'),
    icon: 'all-tickets',
    show: () => !isTransferred.value,
    disabled: () => !hasTicketCreateAccess.value,
    disabledText: __('You have no permission to create tickets in any group.'),
    onClick: () => router.push(chatTicketCreateRoute(props.sessionId)),
  },
  {
    key: 'transfer',
    label: __('Transfer to another topic'),
    icon: 'forward',
    show: () => isOwnSession.value && topics.value.some(({ id }) => id !== session.value?.topic.id),
    disabled: () => isClosed.value,
    disabledText: __('This conversation is closed.'),
    onClick: () => {
      openDetail.value = 'transfer'
    },
  },
  {
    key: 'tags',
    label: __('Manage chat tags'),
    icon: 'tag',
    show: () => isOwnSession.value,
    onClick: () => {
      openDetail.value = 'tags'
    },
  },
  {
    key: 'meta',
    label: __('Show meta data'),
    icon: 'info-circle',
    onClick: () => {
      openDetail.value = 'meta'
    },
  },
]

// The names the system sends along are not translated by it.
const endingName = computed(() => {
  const name = ending.value?.name

  if (name === 'Anonymous') return i18n.t('Anonymous')
  if (name === 'System') return i18n.t('System')

  return name
})

// With the time it ended in front, like the old interface. A conversation loaded when it was over
//   names no one and has no time: its last change may be a rename or a tag after the end.
const endingNote = computed<ChatFooterNoteData>(() => {
  if (isTransferred.value)
    return { text: i18n.t('This conversation was transferred to another chat.') }

  if (!ending.value) return { text: i18n.t('This conversation is closed.') }

  const text =
    ending.value.reason === 'left'
      ? i18n.t('%s left the conversation.', endingName.value)
      : i18n.t('%s closed the conversation.', endingName.value)

  return { text, time: ending.value.at }
})

const handlingAgentName = useChatAgentName(handlingAgent)

// Why a conversation that is still going on is not the agent's to write into.
const readOnlyNote = computed<ChatFooterNoteData | undefined>(() => {
  if (isWaiting.value) return { text: i18n.t('This conversation is waiting for an agent.') }
  if (handlingAgent.value)
    return { text: i18n.t('This conversation is handled by %s.', handlingAgentName.value) }

  return undefined
})

// The thread tells how it ended; the footer keeps the way to a ticket, or why the agent cannot write.
const footerNote = computed(() => (isClosed.value ? undefined : readOnlyNote.value))

const canCreateTicket = computed(() => isClosed.value && !isTransferred.value)

const hasFooter = computed(
  () => !canWrite.value && (Boolean(footerNote.value) || canCreateTicket.value),
)

const threadEndingNote = computed(() => (isClosed.value ? endingNote.value : undefined))

// A session the agent still runs would come back with the next state: only one they can neither
//   write into nor end is theirs to let go.
const canClose = computed(() => !canWrite.value && !canEnd.value)

const { waitForConfirmation } = useConfirmation()

const confirmEnd = async () => {
  const confirmed = await waitForConfirmation(__('This will end the conversation with %s.'), {
    headerTitle: __('Are you sure you want to end the conversation?'),
    textPlaceholder: [title.value],
    buttonLabel: __('End conversation'),
    buttonVariant: 'danger',
  })

  // The conversation can end on its own while the dialog is open, and the handler already tells
  //   the agent when ending it fails.
  if (confirmed && !isClosed.value) await end().catch(() => undefined)
}

// Where Escape in the message input leaves the Tab loop of the inputs to: from the window, the
//   page's order reaches its buttons.
const focusWindow = () => windowElement.value?.focus()

// Without scrolling: the row of windows would move to fit one that is partly out of view.
const keepFocusInWindow = () => windowElement.value?.focus({ preventScroll: true })
</script>

<template>
  <section
    ref="window"
    class="relative flex min-h-0 min-w-0 flex-col overflow-hidden rounded-xl border border-neutral-100 bg-neutral-50 contain-size focus:outline-0 focus-visible:outline-1 focus-visible:-outline-offset-1 focus-visible:outline-blue-800 dark:border-gray-900 dark:bg-gray-500"
    :aria-label="title"
    tabindex="-1"
  >
    <!-- `contain-size` keeps the content out of the window's height, so the rows share the page height
      and a too short window clips; `relative` keeps the composer's hidden label inside. Inside the
      root on purpose: before it, the development build renders a fragment root, which the transition
      group cannot animate out. -->
    <ChatWindowHeader
      ref="header"
      :name="name"
      :title="title"
      :is-renamable="isOwnSession"
      :is-closed="isClosed"
      :is-waiting="isWaiting"
      :can-end="canEnd"
      :can-close="canClose"
      :ending="ending"
      :is-ending="isEnding"
      :actions="session ? actions : []"
      :rename="rename"
      @end="confirmEnd"
      @close="$emit('close')"
    />
    <CommonDivider class="px-3" />

    <template v-if="session">
      <ChatConnectionLine :session="session" />

      <!-- The details float over the thread, which stays visible below them. Keyed, so a topic
        picked for a transfer does not survive a switch to another section. -->
      <div class="relative flex min-h-0 grow flex-col">
        <ChatWindowDetails
          v-if="openDetail"
          :key="openDetail"
          ref="details"
          :session="session"
          :topics="topics"
          :view="openDetail"
          :is-closed="isClosed"
          :transfer="transfer"
          @done="closeDetail"
          @transferred="$emit('close')"
        />

        <ChatThread
          :entries="entries"
          :url="session.url"
          :is-customer-typing="isCustomerTyping"
          :unread-message-ids="unreadMessageIds.get(sessionId)"
          :ending-note="threadEndingNote"
          @leave="keepFocusInWindow"
        />
      </div>

      <!-- Over, or not the agent's to write into: a found session of a colleague reads the same way. -->
      <!-- As tall as the composer: the buttons set the height. -->
      <footer v-if="hasFooter" class="flex flex-wrap items-center justify-between gap-3 px-3 py-2">
        <ChatFooterNote :note="footerNote" />

        <!-- A transferred conversation goes on with another agent, who turns it into a ticket. -->
        <ChatTicketCreateButton v-if="canCreateTicket" class="ms-auto" :session-id="sessionId" />
      </footer>

      <ChatComposer
        v-if="canWrite"
        ref="composer"
        :send="sendMessage"
        @typing="sendTyping"
        @leave="focusWindow"
      />
    </template>

    <!-- Without the conversation the window stays, so the agent can try again. -->
    <template v-else>
      <CommonLoader class="grow px-3 py-2" :loading="isLoading" :error="loadErrorNote" />

      <footer v-if="loadErrorNote" class="flex items-center justify-end gap-3 p-3">
        <CommonButton variant="primary" size="medium" @click="reload">
          {{ $t('Try again') }}
        </CommonButton>
      </footer>
    </template>
  </section>
</template>
