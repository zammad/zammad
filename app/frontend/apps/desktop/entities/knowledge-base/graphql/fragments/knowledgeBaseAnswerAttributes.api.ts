import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerPolicyFragmentDoc } from './knowledgeBaseAnswerPolicy.api';
export const KnowledgeBaseAnswerAttributesFragmentDoc = gql`
    fragment knowledgeBaseAnswerAttributes on KnowledgeBaseAnswer {
  ...knowledgeBaseAnswerPolicy
  visibility
  visibilitySchedules {
    visibility
    scheduledAt
  }
  internalAt
  publishedAt
  archivedAt
  translation(locale: $locale) {
    id
    title
    content {
      id
      bodyWithUrls
      bodyForEditing @include(if: $withBodyForEditing)
    }
    editedAt
    editedBy {
      id
      firstname
      lastname
      fullname
    }
    navigation @include(if: $withNavigation) {
      index
      totalCount
      previousAnswer {
        id
        translation(locale: $locale) {
          id
          title
        }
      }
      nextAnswer {
        id
        translation(locale: $locale) {
          id
          title
        }
      }
    }
    kbLocale {
      id
      systemLocale {
        locale
      }
    }
  }
  category {
    id
    breadcrumb {
      id
      translation(locale: $locale) {
        id
        title
      }
      categoryIcon
      iconSet
      visibility(locale: $locale)
    }
  }
  tags
  attachments {
    id
    internalId
    name
    size
    type
    preferences
  }
}
    ${KnowledgeBaseAnswerPolicyFragmentDoc}`;