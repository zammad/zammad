# Take Home Notes

## Assumptions

The instructions state `Build a lightweight widget in the dashboard that shows all tickets created by today.`

- This would imply I should be adding a widget here: <http://localhost:3000/#dashboard>
- However the link for for dashboard on the doc leads here: <http://localhost:3000/desktop>
- Normally I'd ask clarifying questions, but as this is the long easter weekend I cannot
- As this is designed to show my skills, I will complete both tasks:
  - a ticket counter for today's tickets in the dashboard with icon
  - a list view for today's tickets in desktop
- The phrasing `created by today` could also mean a few different things. I will display all tickets created today

## What would I do with more time

- Change the color on the calendar icon from blue to green
- Perhaps change the icon to red if the amount of tickets submitted today is above the daily average
  - This will indicate if there are issues affecting many users
- Have all tests be successful
  - There are failures not related to my changes (WhatsApp, Zoom, Mailers)
  - If I had more time I'd fully configure the app and stub out API calls I do not have access to
  - I would solve the HashAlignment issue covered below

## Issues

- There is no pleasing RuboCop sometimes. These 3 lines will not pass:
  - `db/migrate/20250419125210_add_all_tickets_to_overview.rb:16`
  - `lib/stats/ticket_created_today.rb:17`
  - `lib/stats/ticket_created_today.rb:18`
- I settled for keeping the codebase consistent to match these existing functions:
  - `db/migrate/20170910000002_out_of_office2.rb:27`
  - `/lib/stats/ticket_escalation.rb:33`
  