# Leasys Ticketing System Implementation

## Overview

This implementation provides a complete guest-accessible ticketing system for Leasys, an internal incident management platform. The system allows both authenticated agents and guest users to submit different types of tickets.

## Features

### 1. Branding & Customization
- **Branding Configuration**: `config/leasys_branding.yml`
  - Company colors, logos, and theme settings
  - Professional design with Material Design principles
  - Support contact information

### 2. Guest Ticket Submission (No Authentication Required)

Three main ticket types are available to guest users:

#### A. Incident Reports
**Route**: `/guest/tickets/incident`

Fields:
- User email address (for communication)
- Affected service dropdown (Applications, Hardware, Other)
- Priority level (3-tier system)
- One-line summary (max 100 characters)
- Detailed description (max 2000 characters)
- Optional screenshot/document attachment (up to 10MB)

#### B. Change Requests
**Route**: `/guest/tickets/change-request`

Fields:
- User email address
- Approver director email address
- Urgency level (1-3)
- Change size (S, M, L, XL, XXL)
- One-line description
- Current state description
- Desired state description
- Testing responsibility
- Optional documentation attachment

#### C. Service Requests
**Route**: `/guest/tickets/service-request`

With dynamic forms based on request type:

**Password Reset**
- System selection (Email, VPN, ERP, CRM, Other)
- Login/username

**Starter Form (New Employee)**
- First name, Last name
- Approver email
- Access requirements

**Leaver Form (Employee Departure)**
- Employee ID or email
- Departure type (Permanent delete or Temporary suspend)

**Transfer Form (Role Change)**
- Employee ID or email
- Description of changes needed

**Information Request**
- Free-text information request field

### 3. Agent Authentication
Agents must be authenticated through the standard Zammad authentication system. Guest users do NOT require login.

### 4. File Attachments
- Maximum file size: 10MB
- Allowed formats: PDF, Images (PNG, JPG, GIF, WebP), Word docs, Excel spreadsheets
- Automatic scanning and validation

### 5. Email Notifications
- **Guest Confirmation**: Automatic confirmation with ticket reference number
- **Status Updates**: Guests receive updates on ticket progress
- **Approver Notifications**: Change request approvers are notified
- **Team Routing**: Service requests routed to appropriate departments

### 6. Security & Rate Limiting
- Rate limiting: 10 submissions per IP per hour
- Input validation and sanitization
- CSRF protection
- File type and size validation

## Technical Stack

### Backend
- **Framework**: Ruby on Rails 7.0+
- **Database**: PostgreSQL (with JSONB support)
- **State Management**: AASM (Acts as State Machine)
- **File Storage**: Active Storage

### Frontend
- **Framework**: Vue 3
- **Styling**: Scoped CSS with Leasys branding
- **Form Validation**: Client-side and server-side
- **Branding**: Composable branding system

## File Structure

```
config/
  └── leasys_branding.yml                 # Branding configuration
  └── routes.rb                            # Guest ticket routes

app/
  frontend/
    components/
      GuestTicketSubmission/
        ├── IncidentForm.vue              # Incident submission form
        ├── ChangeRequestForm.vue         # Change request form
        └── ServiceRequestForm.vue        # Service request form
    composables/
      └── useBranding.ts                  # Branding composable
  
  models/
    ├── guest_ticket.rb                   # Main ticket model
    └── guest_ticket_attachment.rb        # Attachment model
  
  controllers/
    api/
      guest/
        └── tickets_controller.rb         # Guest ticket API endpoints
  
  mailers/
    └── guest_ticket_mailer.rb            # Email notifications
  
  views/
    guest_ticket_mailer/
      ├── confirmation_email.html.erb     # Confirmation email
      └── status_update_email.html.erb    # Status update email

db/
  migrate/
    ├── [timestamp]_create_guest_tickets.rb
    └── [timestamp]_create_guest_ticket_attachments.rb
```

## API Endpoints

### POST /api/guest/tickets/incident
Submit an incident report
```json
{
  "userEmail": "user@company.com",
  "service": "applications|hardware|other",
  "priority": "critical|high|normal",
  "summary": "Brief issue description",
  "description": "Detailed description",
  "attachment": "file (optional)"
}
```

### POST /api/guest/tickets/change-request
Submit a change request
```json
{
  "userEmail": "user@company.com",
  "approverEmail": "director@company.com",
  "urgency": "1|2|3",
  "changeSize": "s|m|l|xl|xxl",
  "description": "Change description",
  "currentState": "Current state description",
  "desiredState": "Desired state description",
  "testing": "Testing responsibility",
  "attachment": "file (optional)"
}
```

### POST /api/guest/tickets/service-request
Submit a service request
```json
{
  "userEmail": "user@company.com",
  "specificData": {
    "requestType": "password_reset|starter_form|leaver_form|transfer_form|information_request",
    // Type-specific fields
  }
}
```

## Database Models

### GuestTicket
- `reference_number`: Unique ticket ID
- `email`: Guest email address
- `title`: Ticket title
- `description`: Full description
- `ticket_type`: Enum (incident, change_request, service_request)
- `status`: Enum (pending, submitted, assigned, in_progress, resolved, closed)
- `aasm_state`: State machine state
- `specific_data`: JSONB storing type-specific data
- `ticket_id`: Optional reference to main Zammad ticket

### GuestTicketAttachment
- `guest_ticket_id`: Foreign key
- `original_filename`: Original file name
- `file`: Active Storage blob reference

## State Machine (AASM)

```
pending → submitted → assigned → in_progress → resolved → closed
```

## Branding Customization

Edit `config/leasys_branding.yml` to customize:
- Company name and logo
- Color scheme
- Font family and theme
- Support contact information

## Setup Instructions

1. **Run migrations**:
   ```bash
   rails db:migrate
   ```

2. **Configure branding** (optional):
   ```yaml
   # config/leasys_branding.yml
   company_name: Leasys
   company_colors:
     primary: '#1e88e5'
   # ... etc
   ```

3. **Set up email delivery**:
   - Configure ActionMailer in `config/environments/production.rb`
   - Set `support_email` in branding config

4. **Enable guest forms** in routes and access them via:
   - `/guest/tickets/incident`
   - `/guest/tickets/change-request`
   - `/guest/tickets/service-request`

## Security Considerations

1. **Rate Limiting**: Implemented per IP address
2. **CSRF Protection**: Rails CSRF tokens on guest forms
3. **Input Validation**: Server-side validation of all inputs
4. **File Validation**: File type and size checks
5. **Email Validation**: RFC compliant email validation
6. **Data Isolation**: Guest tickets separate from agent tickets initially

## Email Templates

Two email templates are provided:

1. **Confirmation Email**
   - Sent immediately upon submission
   - Contains ticket reference number
   - Next steps information

2. **Status Update Email**
   - Sent when ticket status changes
   - Includes current status and update message
   - Custom message support

## Extending the System

### Add Custom Fields
Edit the form component and add to `specific_data` JSONB:
```ruby
specific_data: {
  incident: {
    service: service,
    priority: priority,
    custom_field: value # Add here
  }
}
```

### Customize Email Templates
Edit templates in `app/views/guest_ticket_mailer/`

### Add New Request Types
1. Add to `ServiceRequestForm.vue`
2. Update validation in `guest_ticket.rb`
3. Implement routing in `create_service_request` action

## Testing

### Manual Testing
1. Visit guest ticket submission pages
2. Fill out forms with valid data
3. Check for confirmation emails
4. Verify database entries

### Unit Tests
```bash
rails test app/models/guest_ticket_test.rb
```

## Troubleshooting

### Emails not sending
- Check ActionMailer configuration
- Verify SMTP settings
- Check email logs

### File upload fails
- Verify file size (max 10MB)
- Check file type (PDF, images, Office docs only)
- Ensure Active Storage is configured

### Rate limiting issues
- Check Redis/cache configuration
- Adjust limits in `validate_guest_submission`

## Future Enhancements

- [ ] Multi-language support
- [ ] SMS notifications
- [ ] Ticket search and tracking portal
- [ ] SLA management
- [ ] Knowledge base integration
- [ ] Chatbot support for common requests
- [ ] Advanced analytics and reporting
- [ ] Integration with external ticketing systems

## Support

For questions or issues:
- Email: support@leasys.com
- Phone: +1-800-LEASYS
- Website: https://support.leasys.com
