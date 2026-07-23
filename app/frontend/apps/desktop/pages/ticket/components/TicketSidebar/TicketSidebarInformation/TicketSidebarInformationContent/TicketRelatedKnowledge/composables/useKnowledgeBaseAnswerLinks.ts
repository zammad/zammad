// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  EnumLinkType,
  type LinkListQuery,
  type TicketAiRelatedKnowledgeBaseAnswersQuery,
} from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { useLinkAddMutation } from '#desktop/pages/ticket/graphql/mutations/linkAdd.api.ts'
import { useLinkRemoveMutation } from '#desktop/pages/ticket/graphql/mutations/linkRemove.api.ts'
import { LinkListDocument } from '#desktop/pages/ticket/graphql/queries/linkList.api.ts'
import { TicketAiRelatedKnowledgeBaseAnswersDocument } from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.api.ts'

export const useKnowledgeBaseAnswerLinks = (ticketId: ID, targetType: string) => {
  const linkAddHandler = new MutationHandler(
    useLinkAddMutation({
      // Add the new link to the ticket's link list right away,
      update: (cache, { data }) => {
        if (!data?.linkAdd?.link) return

        const { link: newLink } = data.linkAdd
        const variables = { objectId: ticketId, targetType: targetType }
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

        // Drop the just-linked answer from the AI suggestions cache, so it no longer shows up
        // under "Suggested by AI" without waiting for the next refetch.
        const aiVariables = { ticketId }
        const existingSuggestions = cache.readQuery<TicketAiRelatedKnowledgeBaseAnswersQuery>({
          query: TicketAiRelatedKnowledgeBaseAnswersDocument,
          variables: aiVariables,
        })

        const suggested = existingSuggestions?.ticketAIRelatedKnowledgeBaseAnswers
        if (!suggested?.answers?.length) return

        const remainingAnswers = suggested.answers.filter(
          (answer) => answer.translation.id !== newLink.item.id,
        )

        if (remainingAnswers.length === suggested.answers.length) return

        cache.writeQuery({
          query: TicketAiRelatedKnowledgeBaseAnswersDocument,
          variables: aiVariables,
          data: {
            ...existingSuggestions,
            ticketAIRelatedKnowledgeBaseAnswers: {
              ...suggested,
              answers: remainingAnswers,
            },
          },
        })
      },
    }),
  )

  const linkAnswer = async (answerId: string) =>
    await linkAddHandler.send({
      input: {
        sourceId: answerId,
        targetId: ticketId,
        type: EnumLinkType.Normal,
      },
    })

  const unlinkAnswer = async (answerId: string) => {
    const linkRemoveHandler = new MutationHandler(
      useLinkRemoveMutation({
        // Remove the link from the ticket's link list right away.
        update: (cache) => {
          const variables = { objectId: ticketId, targetType: targetType }
          const existingLinks = cache.readQuery<LinkListQuery>({
            query: LinkListDocument,
            variables,
          })

          if (!existingLinks) return

          cache.writeQuery({
            query: LinkListDocument,
            variables,
            data: {
              linkList: existingLinks.linkList?.filter((link) => link.item.id !== answerId),
            },
          })
        },
      }),
    )

    return linkRemoveHandler.send({
      input: {
        // Source and target ids are swapped to stay consistent with the link add convention.
        sourceId: answerId,
        targetId: ticketId,
        type: EnumLinkType.Normal,
      },
    })
  }

  return { linkAnswer, unlinkAnswer }
}
