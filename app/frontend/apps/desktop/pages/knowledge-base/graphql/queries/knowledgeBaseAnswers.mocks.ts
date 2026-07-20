import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseAnswers.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseAnswersQuery(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseAnswersDocument, defaults)
}

export function waitForKnowledgeBaseAnswersQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseAnswersQuery>(Operations.KnowledgeBaseAnswersDocument)
}

export function mockKnowledgeBaseAnswersQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseAnswersDocument, message, extensions);
}
