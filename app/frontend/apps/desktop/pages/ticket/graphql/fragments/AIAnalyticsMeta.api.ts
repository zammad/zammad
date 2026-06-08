import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const AiAssistantAnalyticsMetaFragmentDoc = gql`
    fragment AIAssistantAnalyticsMeta on AIAnalyticsMetadata {
  run {
    id
  }
  usage {
    userHasProvidedFeedback
  }
}
    `;