import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseAnswerLiveUserAttributesFragmentDoc = gql`
    fragment knowledgeBaseAnswerLiveUserAttributes on KnowledgeBaseAnswerLiveUser {
  user {
    id
    firstname
    lastname
    fullname
    email
    vip
    outOfOffice
    outOfOfficeStartAt
    outOfOfficeEndAt
    active
    image
  }
  apps {
    name
    editing
    lastInteraction
  }
}
    `;