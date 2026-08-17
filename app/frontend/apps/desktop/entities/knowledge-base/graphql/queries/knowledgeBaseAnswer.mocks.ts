import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseAnswer.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseAnswerQuery(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseAnswerDocument, defaults)
}

export function waitForKnowledgeBaseAnswerQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseAnswerQuery>(Operations.KnowledgeBaseAnswerDocument)
}

export function mockKnowledgeBaseAnswerQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseAnswerDocument, message, extensions);
}
