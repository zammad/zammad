import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const ChatPreferencesAttributesFragmentDoc = gql`
    fragment chatPreferencesAttributes on ChatPreferences {
  maxWindows
  alternativeName
  avatarEnabled
  topics {
    topic {
      ...chatTopicAttributes
    }
    active
    phrases
  }
  hasTicketCreateAccess
}
    `;