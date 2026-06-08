import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './betaUiSendFeedback.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockBetaUiSendFeedbackMutation(defaults: Mocks.MockDefaultsValue<Types.BetaUiSendFeedbackMutation, Types.BetaUiSendFeedbackMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.BetaUiSendFeedbackDocument, defaults)
}

export function waitForBetaUiSendFeedbackMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.BetaUiSendFeedbackMutation>(Operations.BetaUiSendFeedbackDocument)
}

export function mockBetaUiSendFeedbackMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.BetaUiSendFeedbackDocument, message, extensions);
}
