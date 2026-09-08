import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseAnswerInfoForPopover.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseAnswerInfoForPopoverQuery(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseAnswerInfoForPopoverDocument, defaults)
}

export function waitForKnowledgeBaseAnswerInfoForPopoverQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseAnswerInfoForPopoverQuery>(Operations.KnowledgeBaseAnswerInfoForPopoverDocument)
}

export function mockKnowledgeBaseAnswerInfoForPopoverQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseAnswerInfoForPopoverDocument, message, extensions);
}
