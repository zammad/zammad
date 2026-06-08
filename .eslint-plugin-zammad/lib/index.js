// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/**
 * @fileoverview Collection of Zammad rules for Eslint.
 * @author Martin Gruner
 */

//------------------------------------------------------------------------------
// Requirements
//------------------------------------------------------------------------------
const requireIndex = require('requireindex')

//------------------------------------------------------------------------------
// Plugin Definition
//------------------------------------------------------------------------------
// import all rules in lib/rules
module.exports = { meta: { name: 'zammad-eslint' }, rules: requireIndex(`${__dirname}/rules`) }
