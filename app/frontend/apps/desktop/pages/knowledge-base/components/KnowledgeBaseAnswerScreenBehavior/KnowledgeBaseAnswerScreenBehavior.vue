<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import {
  type EnumKnowledgeBaseAnswerScreen,
  EnumKnowledgeBaseAnswerScreenBehavior,
} from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonDropdown from '#desktop/components/CommonDropdown/CommonDropdown.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { useUserCurrentKnowledgeBaseAnswerScreenBehaviorMutation } from '#desktop/entities/user/current/graphql/mutations/userCurrentKnowledgeBaseAnswerScreenBehavior.api.ts'

import {
  behaviorOptionLookup,
  behaviorOptions,
  PREFERENCE_KEY,
  screenBehaviorFromPreferences,
} from './behaviorOptions.ts'

interface Props {
  // Which of the two saving screens this control configures. They are stored - and offered - apart
  //   from each other, see behaviorOptions.ts.
  screen: EnumKnowledgeBaseAnswerScreen
}

const props = defineProps<Props>()

const sessionStore = useSessionStore()
const { setUserPreference } = sessionStore
const { user } = storeToRefs(sessionStore)

const { notify } = useNotifications()

const screenBehaviorMutation = new MutationHandler(
  useUserCurrentKnowledgeBaseAnswerScreenBehaviorMutation(),
)

// No admin default to fall back to, unlike the ticket control's `ticket_secondary_action` - see
//   behaviorOptions.ts, which also owns the read so the handler cannot disagree with the control.
const screenBehavior = computed(() =>
  screenBehaviorFromPreferences(props.screen, user.value?.preferences),
)

const items = computed(() => behaviorOptions(props.screen))

const selectedItem = computed({
  get: () => behaviorOptionLookup(props.screen)[screenBehavior.value],
  set: (item: MenuItem) => {
    screenBehaviorMutation
      .send({
        screen: props.screen,
        behavior: item.key as EnumKnowledgeBaseAnswerScreenBehavior,
      })
      .then(() => {
        // Written into the session store as well, so the choice takes effect on this save rather
        //   than only after the next reload.
        setUserPreference(PREFERENCE_KEY[props.screen], item.key)

        notify({
          id: 'knowledge-base-answer-screen-behavior-updated',
          type: NotificationTypes.Success,
          message: __('Knowledge base answer screen behavior updated successfully.'),
        })
      })
  },
})
</script>

<template>
  <CommonDropdown v-model="selectedItem" :items="items" orientation="top" />
</template>
