class GuestTicketMailer < ApplicationMailer
  default from: 'support@leasys.com'

  def confirmation_email
    @guest_ticket = params[:guest_ticket]
    @reference_number = @guest_ticket.reference_number

    mail(
      to: @guest_ticket.email,
      subject: "Ticket Confirmation - #{@reference_number} - Leasys Support",
    )
  end

  def status_update_email
    @guest_ticket = params[:guest_ticket]
    @reference_number = @guest_ticket.reference_number
    @status = @guest_ticket.aasm_state
    @message = params[:message]

    mail(
      to: @guest_ticket.email,
      subject: "Ticket Update - #{@reference_number} - Leasys Support",
    )
  end

  def approver_notification
    @guest_ticket = params[:guest_ticket]
    @approver_email = params[:approver_email]
    @reference_number = @guest_ticket.reference_number

    mail(
      to: @approver_email,
      subject: "Change Request Approval Needed - #{@reference_number} - Leasys",
    )
  end
end
