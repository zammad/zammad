class App.FirstStepsClues extends App.CluesBase
  clues: [
    {
      container: '.user-menu .user .dropdown-menu'
      headline: __('Personal Settings')
      text: __('Here you can sign out, change the frontend language, and see your last viewed items.')
      actions: [
        'hover .navigation',
        'click .user-menu .user .js-action',
        'hover .user-menu .user'
      ]
    }
    {
      container: '.user-menu .add'
      headline: __('Create')
      text: __('Here you can create new tickets and customers.')
      actions: [
        'hover .navigation',
        'hover .user-menu .add'
      ]
    }
    {
      container: '.js-overviewsMenuItem'
      headline: __('Overviews')
      text: __('Here you find your ticket overviews for open, assigned, and escalated tickets.')
      actions: [
        'hover'
      ]
    }
    {
      container: '.search-holder'
      headline: __('Search')
      text: __('Here you can search for tickets, customers, and organizations. Use the asterisk §*§ to find anything, e.g. §smi*§ or §rosent*l§. You also can use ||quotation marks|| for searching phrases: §"some phrase"§.')
      actions: [
        'hover'
      ]
    }
    {
      container: '.user-menu .user .navbar-link-agent-docs'
      headline: __('Help')
      text: __('Need help? Check the Zammad Documentation for detailed guidance.')
      actions: [
        'click .user-menu .user .js-action',
        'hover .user-menu .navbar-link-agent-docs'
      ]
    }
  ]
