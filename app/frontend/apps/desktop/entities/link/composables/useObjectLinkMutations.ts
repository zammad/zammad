// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { toValue } from 'vue'

import { EnumLinkType, type LinkListQuery } from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { useLinkAddMutation } from '../graphql/mutations/linkAdd.api.ts'
import { useLinkRemoveMutation } from '../graphql/mutations/linkRemove.api.ts'
import { LinkListDocument } from '../graphql/queries/linkList.api.ts'

import type { MaybeRefOrGetter } from 'vue'

// Adding and removing links of one object, keeping the `linkList` it is rendered from in step
//   without a refetch. The companion of useObjectLinks, which reads that list.
//
// `objectId` is the object whose list is maintained — a ticket, or a knowledge base answer
//   *translation* (links hang off the translation, so they differ per locale). It is taken as a
//   ref or getter because the knowledge base case swaps it when the edited locale changes.
export const useObjectLinkMutations = (
  // Nullable, because the knowledge base case reads it off a GraphQL field that is null while the
  //   edited locale has no translation yet - there is nothing to link to then, and the callers gate
  //   on that before offering the action.
  objectId: MaybeRefOrGetter<string | null | undefined>,
  targetType: string,
) => {
  const listVariables = () => ({ objectId: toValue(objectId), targetType })

  const linkAddHandler = new MutationHandler(
    useLinkAddMutation({
      update: (cache, { data }) => {
        if (!data?.linkAdd?.link) return

        const { link: newLink } = data.linkAdd
        const variables = listVariables()

        let existingLinks = cache.readQuery<LinkListQuery>({
          query: LinkListDocument,
          variables,
        })

        const alreadyPresent = existingLinks?.linkList?.find(
          (link) => link.item.id === newLink.item.id && link.type === newLink.type,
        )

        if (alreadyPresent) return

        existingLinks = {
          ...existingLinks,
          linkList: [...(existingLinks?.linkList || []), newLink],
        }

        cache.writeQuery({ query: LinkListDocument, data: existingLinks, variables })
      },
    }),
  )

  // `sourceId` is the *other* object and `targetId` the one whose list this is — swapped, to stay
  //   consistent with what the old interface writes.
  const addLink = async (otherId: string, type: EnumLinkType = EnumLinkType.Normal) =>
    linkAddHandler.send({
      input: { sourceId: otherId, targetId: toValue(objectId) as string, type },
    })

  const removeLink = async (otherId: string, type: EnumLinkType = EnumLinkType.Normal) => {
    const linkRemoveHandler = new MutationHandler(
      useLinkRemoveMutation({
        update: (cache) => {
          const variables = listVariables()

          const existingLinks = cache.readQuery<LinkListQuery>({
            query: LinkListDocument,
            variables,
          })

          if (!existingLinks) return

          cache.writeQuery({
            query: LinkListDocument,
            variables,
            data: {
              linkList: existingLinks.linkList?.filter(
                (link) => !(link.item.id === otherId && link.type === type),
              ),
            },
          })
        },
      }),
    )

    return linkRemoveHandler.send({
      input: { sourceId: otherId, targetId: toValue(objectId) as string, type },
    })
  }

  return { addLink, removeLink }
}
