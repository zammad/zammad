// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

// The default export can be removed, when we have more then one type defined, but for now it's for enum not working
// without a eslint error.
enum ViewTransitions {
  NEXT = 'next',
  PREV = 'prev',
  REPLACE = 'replace',
}

export default ViewTransitions
