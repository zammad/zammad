import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseFeedTokenRenew.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseFeedTokenRenewMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseFeedTokenRenewMutation, Types.KnowledgeBaseFeedTokenRenewMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseFeedTokenRenewDocument, defaults)
}

export function waitForKnowledgeBaseFeedTokenRenewMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseFeedTokenRenewMutation>(Operations.KnowledgeBaseFeedTokenRenewDocument)
}

export function mockKnowledgeBaseFeedTokenRenewMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseFeedTokenRenewDocument, message, extensions);
}
