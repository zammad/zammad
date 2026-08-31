// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { remapUserErrorFields } from '#shared/errors/utils.ts'
import {
  EnumKnowledgeBaseVisibility,
  type KnowledgeBaseCreateAnswerInput,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { useKnowledgeBaseAnswerAddMutation } from '../graphql/mutations/knowledgeBaseAnswerAdd.api.ts'

import type { KnowledgeBaseAnswerCreateFormData } from '../types.ts'

// The backend reports a validation error under the path of the record that carries it: the title
//   lives on the answer's translation, which is not what this form calls the field.
const FORM_FIELD_BY_ERROR_FIELD = {
  'translations.title': 'title',
}

export const useKnowledgeBaseAnswerCreate = () => {
  const { notify } = useNotifications()

  const answerAddMutation = new MutationHandler(useKnowledgeBaseAnswerAddMutation())

  // Everything the answer *is*; the files are not in here — they are already in the upload cache
  //   of the form, which is what `formId` hands over.
  const buildAnswerInput = (
    data: KnowledgeBaseAnswerCreateFormData,
    formId: string,
  ): KnowledgeBaseCreateAnswerInput => ({
    // The field works with internal ids (the updater builds its options from records).
    categoryId: convertToGraphQLId('KnowledgeBase::Category', data.categoryId),
    title: data.title,
    body: data.body ?? '',
    formId,
    tags: data.tags ?? [],
    // The state alone, effective at once: scheduling a transition for later is an edit, so this
    //   form carries no date to go with it.
    //
    // The field starts out on `draft` (the form updater seeds it), so the fallback only covers a
    //   form that never resolved one - the mutation wants the state named rather than inferred
    //   from an absent argument.
    visibility: data.visibility ?? EnumKnowledgeBaseVisibility.Draft,
  })

  // @returns the created answer, or undefined when there was nothing to submit into
  const createAnswer = async (data: KnowledgeBaseAnswerCreateFormData, formId?: string) => {
    // Only reachable if the form never got an id to keep its uploads under - which is what hands
    //   the files over, so there is nothing to submit without it. Which knowledge base the answer
    //   goes to is not this call's business: the backend resolves the single one itself.
    if (!formId) {
      notify({
        id: 'knowledge-base-answer-create-error',
        type: NotificationTypes.Error,
        message: __('The answer could not be created.'),
      })
      return undefined
    }

    const result = await answerAddMutation
      .send({
        input: buildAnswerInput(data, formId),
        // The locale of the call: the title and body are written into it, and the answer comes
        //   back in it — which matters because it lands in the cache the next page reads from.
        locale: data.locale,
      })
      .catch((error) => {
        throw remapUserErrorFields(error, FORM_FIELD_BY_ERROR_FIELD)
      })

    return result?.knowledgeBaseAnswerAdd?.answer ?? undefined
  }

  return { createAnswer }
}
