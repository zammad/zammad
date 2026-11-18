// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import type { EntityAttributeSingleSelect } from '#shared/components/EntityAttributes/attributes/AttributeSingleSelect/attributeSingleSelectTypes.ts'
import { translateOption } from '#shared/components/EntityAttributes/utils.ts'
import type { FieldEditorNotice } from '#shared/components/Form/fields/FieldEditor/types.ts'
import type { FormValues } from '#shared/components/Form/types.ts'
import { useEntityAttributes } from '#shared/entities/core/attributes/composables/useEntityAttributes.ts'
import type { TicketArticleFormValues } from '#shared/entities/ticket-article/action/plugins/types.ts'
import type { TicketArticleTranslation } from '#shared/entities/ticket-article/stores/types.ts'
import { EnumObjectManagerObjects, type TicketArticlesQuery } from '#shared/graphql/types.ts'
import { edgesToArray } from '#shared/utils/helpers.ts'

// What the reply editor says while the article it was opened from is displayed translated: the
// agent reads their own language there, and the customer wrote in another one.
export const useAnsweredArticleTranslationNotice = (
  formValues: Ref<FormValues>,
  articles: Ref<TicketArticlesQuery | undefined>,
  articleTranslation: TicketArticleTranslation,
) => {
  // A string, so typing in the reply does not search the articles again.
  const answeredArticleId = computed(
    () => (formValues.value.article as TicketArticleFormValues | undefined)?.answeredArticleId,
  )

  const answeredArticle = computed(() => {
    const articleId = answeredArticleId.value
    if (!articleId) return undefined

    return [
      ...edgesToArray(articles.value?.firstArticles),
      ...edgesToArray(articles.value?.articles),
    ].find((article) => article.id === articleId)
  })

  const { attributesLookup } = useEntityAttributes(EnumObjectManagerObjects.TicketArticle)

  // The name the article meta shows for the code. Nothing for a code without one: the agent
  // reads a plain hint rather than a raw code.
  const languageName = (code?: Maybe<string>) => {
    const attribute = attributesLookup.value.get('detected_language') as
      | EntityAttributeSingleSelect
      | undefined
    if (!code || !attribute) return undefined

    return translateOption(attribute, attribute.dataOption.historical_options?.[code]) || undefined
  }

  const notice = computed<FieldEditorNotice | undefined>(() => {
    const article = answeredArticle.value
    if (!article || !articleTranslation.isTranslationDisplayed(article.id)) return undefined

    const language = languageName(article.detectedLanguage)
    if (!language) {
      return {
        key: article.id,
        text: __('The original message was written in another language.'),
      }
    }

    return {
      key: article.id,
      text: __('The original message was written in %s.'),
      textPlaceholder: [language],
    }
  })

  return { notice }
}
