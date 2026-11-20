// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { nextTick, ref, useId } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useTagAssignmentAddMutation } from '#shared/entities/tags/graphql/mutations/assignment/add.api.ts'
import { useTagAssignmentRemoveMutation } from '#shared/entities/tags/graphql/mutations/assignment/remove.api.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import {
  authenticationGeneration,
  authenticationInvalidated,
} from '#shared/server/apollo/utils/authenticationState.ts'

import type { TagAssignmentOptions, TagEdit, TagState } from '../types.ts'

const placeTag = (tags: readonly string[], tag: string, present: boolean, index = -1) => {
  if (!present) return tags.filter((name) => name !== tag)
  if (tags.includes(tag)) return tags
  if (index < 0) return [...tags, tag]

  return [...tags.slice(0, index), tag, ...tags.slice(index)]
}

const tagKey = ({ cacheId, tag }: Pick<TagEdit, 'cacheId' | 'tag'>) => `${cacheId}\u0000${tag}`

const isOutdated = (edit: TagEdit) => edit.generation !== authenticationGeneration()

export const useTagAssignment = (options: TagAssignmentOptions) => {
  const { notify } = useNotifications()

  const addMutation = new MutationHandler(useTagAssignmentAddMutation({}), {
    errorNotificationMessage: __('The tag could not be added.'),
  })

  const removeMutation = new MutationHandler(useTagAssignmentRemoveMutation({}), {
    errorNotificationMessage: __('The tag could not be removed.'),
  })

  const newTagId = `new-tag-${useId()}`
  const isNewTagVisible = ref(false)

  const hideNewTag = () => {
    isNewTagVisible.value = false
  }

  // Opens the field's own input right away, so adding a tag is one click rather than two.
  const showNewTag = async () => {
    isNewTagVisible.value = true

    await nextTick()

    const activate = getNode(newTagId)?.context?.activate

    if (typeof activate === 'function') activate()
  }

  // Written into the cache at once, as the record's own updates would bring a change round only
  //   later, and a failed call none at all. Each write starts from the list the cache holds then,
  //   so a change from elsewhere that arrived meanwhile stays, and a failed edit undoes only itself.
  const updateTags = (
    { cacheId }: TagEdit,
    update: (tags: readonly string[]) => readonly string[],
  ) => {
    getApolloClient().cache.modify({
      id: cacheId,
      fields: { tags: (current) => update(Array.isArray(current) ? current : []) },
    })
  }

  // A failed edit shows what the server holds for its tag again, unless a later edit of the same tag
  //   is still on its way, which decides what is shown once it is answered.
  const tagStates = new Map<string, TagState>()

  const settleEdit = (edit: TagEdit, stored: boolean) => {
    const key = tagKey(edit)
    const state = tagStates.get(key)

    if (!state) return

    state.pending -= 1

    if (stored) state.stored = edit.add
    else if (!state.pending && !isOutdated(edit))
      updateTags(edit, (tags) => placeTag(tags, edit.tag, state.stored, state.index))

    if (!state.pending) tagStates.delete(key)
  }

  const sendEdit = async (edit: TagEdit) => {
    const variables = { objectId: edit.objectId, tag: edit.tag }

    try {
      if (edit.add) await addMutation.send(variables)
      else await removeMutation.send(variables)

      settleEdit(edit, true)

      notify({
        type: NotificationTypes.Success,
        id: edit.add ? 'tag-added' : 'tag-removed',
        message: edit.add ? __('Tag added successfully.') : __('Tag removed successfully.'),
      })
    } catch {
      // The handler reports the failure itself.
      settleEdit(edit, false)
    }
  }

  // One at a time: the server takes them in the agent's order, and an earlier call superseded on the
  //   same mutation would fail without its notification.
  let lastEditSent = Promise.resolve()

  const editTags = (tag: string, add: boolean) => {
    const entity = options.entity()
    const cacheId = entity && getApolloClient().cache.identify(entity)

    // The controls stay mounted while the logout is still on its way.
    if (!entity || !cacheId || authenticationInvalidated()) return false

    const edit: TagEdit = {
      objectId: entity.id,
      cacheId,
      tag,
      add,
      generation: authenticationGeneration(),
    }
    const key = tagKey(edit)
    const tags = options.tags()
    const state = tagStates.get(key) ?? {
      stored: tags.includes(tag),
      index: tags.indexOf(tag),
      pending: 0,
    }

    state.pending += 1
    tagStates.set(key, state)

    updateTags(edit, (current) => placeTag(current, tag, add))

    lastEditSent = lastEditSent.then(() => {
      if (!isOutdated(edit)) return sendEdit(edit)

      settleEdit(edit, false)
    })

    return true
  }

  // `unknown`, as that is what the field's `input` event hands over. Tells whether it was added.
  const addTag = (value: unknown) => {
    const tag = value as string

    if (!tag || options.tags().includes(tag)) return false

    return editTags(tag, true)
  }

  const removeTag = (tag: string) => {
    if (!options.tags().includes(tag)) return

    editTags(tag, false)
  }

  return { addTag, removeTag, newTagId, isNewTagVisible, showNewTag, hideNewTag }
}
