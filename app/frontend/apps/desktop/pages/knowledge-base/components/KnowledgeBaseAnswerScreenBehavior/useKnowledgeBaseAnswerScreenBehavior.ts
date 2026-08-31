// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { toRef, toValue } from 'vue'
import { useRouter } from 'vue-router'

import {
  type EnumKnowledgeBaseAnswerScreen,
  EnumKnowledgeBaseAnswerScreenBehavior,
} from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import {
  knowledgeBaseAnswerCreateRoute,
  knowledgeBaseAnswerRoute,
  knowledgeBaseBrowseRoute,
} from '#desktop/entities/knowledge-base/utils/routeLocation.ts'
import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'

import { screenBehaviorFromPreferences } from './behaviorOptions.ts'

import type { MaybeRefOrGetter } from 'vue'
import type { RouteLocationNamedRaw } from 'vue-router'

interface SavedAnswer {
  id: string
  category: { id: string }
}

// What happens after an answer was saved, shared by the edit and the create view. Which options a
//   screen offers, which preference it reads and what it falls back to are all behaviorOptions.ts's
//   business; every option a screen can hold is handled here.
export const useKnowledgeBaseAnswerScreenBehavior = (options: {
  currentTaskbarTabId: MaybeRefOrGetter<string | undefined>
  localeCode: MaybeRefOrGetter<string>
  screen: EnumKnowledgeBaseAnswerScreen
}) => {
  const { deleteTaskbarTab } = useUserCurrentTaskbarTabsStore()

  const user = toRef(useSessionStore(), 'user')

  const router = useRouter()

  // `replace`, and awaited before the tab goes. `deleteTaskbarTab` drops the tab from the list
  //   synchronously, and LayoutTaskbarTabContent unmounts this view the moment it is gone, so
  //   deleting first would blank the panel while the old route is still showing and could even let
  //   the removal handler redirect over the pending navigation. `replace` rather than `push` so the
  //   closed tab's URL does not stay in history, where going back would recreate the tab that was
  //   just closed.
  const leaveFor = async (target: RouteLocationNamedRaw) => {
    const taskbarTabId = toValue(options.currentTaskbarTabId)

    await router.replace(target)

    if (taskbarTabId) deleteTaskbarTab(taskbarTabId)
  }

  const handleScreenBehavior = async (answer: SavedAnswer) => {
    const localeCode = toValue(options.localeCode)
    const behavior = screenBehaviorFromPreferences(options.screen, user.value?.preferences)

    if (behavior === EnumKnowledgeBaseAnswerScreenBehavior.CloseTabAndOpenCategory) {
      await leaveFor(knowledgeBaseBrowseRoute(localeCode, answer.category.id))
      return
    }

    // Create-only: this tab is done, and the next answer starts in the category this one was filed
    //   in. A tab of its own rather than this one emptied - `knowledgeBaseAnswerCreateRoute` mints
    //   a tab id per call, which is what gets the next answer its own form id, and with it a fresh
    //   upload cache and no stored draft to inherit.
    //
    // The internal id, which is what that route's `categoryId` query is: the form's own category
    //   field works with internal ids, and the updater reads it back from there to preselect it.
    if (behavior === EnumKnowledgeBaseAnswerScreenBehavior.CloseTabAndAddAnother) {
      await leaveFor(
        knowledgeBaseAnswerCreateRoute(localeCode, getIdFromGraphQLId(answer.category.id)),
      )
      return
    }

    // Edit-only, and nothing to do for it: the tab holds the answer and stays open on it. Which
    //   values its form is left with is the view's own business - the `reset` it returns from its
    //   submit handler.
    if (behavior === EnumKnowledgeBaseAnswerScreenBehavior.StayOnTab) return

    await leaveFor(knowledgeBaseAnswerRoute(localeCode, answer.id))
  }

  return { handleScreenBehavior }
}
