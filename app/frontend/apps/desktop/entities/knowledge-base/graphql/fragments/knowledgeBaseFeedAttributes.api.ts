import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseFeedAttributesFragmentDoc = gql`
    fragment knowledgeBaseFeedAttributes on KnowledgeBaseFeed {
  knowledgeBasePath
  categoryPath
}
    `;