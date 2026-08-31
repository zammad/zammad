// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { remapUserErrorFields } from '#shared/errors/utils.ts'
import { EnumUserErrorException } from '#shared/graphql/types.ts'
import type { KnowledgeBaseUpdateAnswerInput } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { useKnowledgeBaseAnswerUpdateMutation } from '../graphql/mutations/knowledgeBaseAnswerUpdate.api.ts'

import type { KnowledgeBaseAnswerEditFormData } from '../types.ts'

// The backend reports a validation error under the path of the record that carries it: the title
//   lives on the answer's translation, which is not what this form calls the field.
const FORM_FIELD_BY_ERROR_FIELD = {
  'translations.title': 'title',
}

export const useKnowledgeBaseAnswerUpdate = () => {
  const answerUpdateMutation = new MutationHandler(useKnowledgeBaseAnswerUpdateMutation())

  // Every attribute is optional here (unlike the create input): an absent one leaves the answer's
  //   stored value alone. `tags` is deliberately not among them - the edit form has no tags field,
  //   and sending an empty array would clear the answer's tags instead of leaving them untouched.
  //
  // The files are not in here: they are already in the upload cache of this form, which is what
  //   `formId` hands over. The updater seeded that cache with the answer's own files when the tab
  //   was opened (FormUpdater::Updater::KnowledgeBase::Answer::Edit#seed_upload_cache), which is
  //   what makes handing it over safe - `attach_upload_cache` deletes every non-inline attachment
  //   of the answer before refilling from it, so an unseeded cache would be a delete-all.
  //   Which is why nothing here falls back to a default: an attribute the form has no value for is
  //   left out, not sent as empty. A `visibility` defaulted to `draft` would unpublish a published
  //   answer, and an empty `body` would wipe the translation - both without anybody asking for it.
  const buildAnswerInput = (
    data: KnowledgeBaseAnswerEditFormData,
    formId: string,
  ): KnowledgeBaseUpdateAnswerInput => ({
    categoryId: convertToGraphQLId('KnowledgeBase::Category', data.categoryId),
    title: data.title,
    formId,
    ...(data.body !== undefined && { body: data.body }),
    //   The state as it is *now*, which is all the mutation takes - a transition scheduled for
    //   later is managed apart from the answer's data.
    ...(data.visibility && { visibility: data.visibility }),
  })

  // @param options.knownAttachments the answer's files as the form was opened with them, so the
  //   backend can tell a foreign change from this editor's own. Saving replays the upload cache and
  //   deletes what is not in it, so a cache seeded before somebody else added a file would delete
  //   their file - Service::KnowledgeBase::Answer::Update::Validator::ConcurrentAttachmentChange
  //   refuses that. It has to be the list from *load* time, not the live one: the answer is
  //   live-updated by its subscription, and reading it back would already show their change and
  //   compare equal.
  // @param options.replaceConcurrentChange the editor was told that somebody else changed the
  //   answer and submitted anyway. Without this the guard above refuses the save again and the
  //   confirmation leads nowhere: the same "warn, then let the user proceed" contract the ticket
  //   update validators follow (`skip_validators`).
  //
  // @returns the updated answer, or undefined when the mutation reported no answer
  const updateAnswer = async (
    answerId: string,
    data: KnowledgeBaseAnswerEditFormData,
    formId: string,
    options: {
      knownAttachments?: { name: string; size: number }[]
      replaceConcurrentChange?: boolean
    } = {},
  ) => {
    const { knownAttachments, replaceConcurrentChange } = options

    const meta = {
      ...(knownAttachments && { knownAttachments }),
      ...(replaceConcurrentChange && {
        skipValidators: [
          EnumUserErrorException.ServiceKnowledgeBaseAnswerUpdateValidatorConcurrentAttachmentChangeError,
        ],
      }),
    }

    const result = await answerUpdateMutation
      .send({
        answerId,
        input: buildAnswerInput(data, formId),
        ...(Object.keys(meta).length > 0 && { meta }),
        // The locale of the call: the title and body are written into it, and the answer comes
        //   back in it — which matters because it lands in the cache the view reads from.
        locale: data.locale,
        // The response re-baselines the open editor, so it has to carry the body in the form the
        //   editor loads - and the cache entity it normalizes into must not lose that field.
        withBodyForEditing: true,
      })
      .catch((error) => {
        throw remapUserErrorFields(error, FORM_FIELD_BY_ERROR_FIELD)
      })

    return result?.knowledgeBaseAnswerUpdate?.answer ?? undefined
  }

  return { updateAnswer }
}
