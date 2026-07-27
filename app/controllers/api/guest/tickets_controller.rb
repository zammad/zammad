module Api
  module Guest
    class TicketsController < ApplicationController
      skip_before_action :authenticate_user!, only: %i[create_incident create_change_request create_service_request]
      before_action :validate_guest_submission, only: %i[create_incident create_change_request create_service_request]

      # POST /api/guest/tickets/incident
      def create_incident
        @guest_ticket = GuestTicket.new(
          ticket_type: :incident,
          email: guest_ticket_params[:userEmail],
          title: guest_ticket_params[:summary],
          description: guest_ticket_params[:description],
          specific_data: {
            incident: {
              service: guest_ticket_params[:service],
              priority: guest_ticket_params[:priority],
            },
          },
        )

        if @guest_ticket.save
          handle_attachment if guest_ticket_params[:attachment].present?
          @guest_ticket.submit
          send_confirmation_email
          render json: { success: true, reference_number: @guest_ticket.reference_number }, status: :created
        else
          render json: { success: false, errors: @guest_ticket.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/guest/tickets/change-request
      def create_change_request
        @guest_ticket = GuestTicket.new(
          ticket_type: :change_request,
          email: guest_ticket_params[:userEmail],
          title: guest_ticket_params[:description],
          description: "Current State: #{guest_ticket_params[:currentState]}\n\nDesired State: #{guest_ticket_params[:desiredState]}\n\nTesting: #{guest_ticket_params[:testing]}",
          specific_data: {
            change_request: {
              approverEmail: guest_ticket_params[:approverEmail],
              urgency: guest_ticket_params[:urgency],
              changeSize: guest_ticket_params[:changeSize],
              currentState: guest_ticket_params[:currentState],
              desiredState: guest_ticket_params[:desiredState],
              testing: guest_ticket_params[:testing],
            },
          },
        )

        if @guest_ticket.save
          handle_attachment if guest_ticket_params[:attachment].present?
          @guest_ticket.submit
          send_confirmation_email
          notify_approver
          render json: { success: true, reference_number: @guest_ticket.reference_number }, status: :created
        else
          render json: { success: false, errors: @guest_ticket.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/guest/tickets/service-request
      def create_service_request
        service_data = service_request_params.merge(request_type: params[:specificData][:requestType])

        @guest_ticket = GuestTicket.new(
          ticket_type: :service_request,
          email: guest_ticket_params[:userEmail],
          title: "Service Request: #{service_data[:requestType]}",
          description: build_service_request_description(service_data),
          specific_data: { service_request: service_data },
        )

        if @guest_ticket.save
          @guest_ticket.submit
          send_confirmation_email
          route_service_request
          render json: { success: true, reference_number: @guest_ticket.reference_number }, status: :created
        else
          render json: { success: false, errors: @guest_ticket.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def guest_ticket_params
        params.permit(
          :userEmail,
          :service,
          :priority,
          :summary,
          :description,
          :attachment,
          :approverEmail,
          :urgency,
          :changeSize,
          :currentState,
          :desiredState,
          :testing,
        )
      end

      def service_request_params
        params.require(:specificData).permit(
          :requestType,
          :system,
          :login,
          :firstName,
          :lastName,
          :approverEmail,
          :accessNeeds,
          :employeeId,
          :departureType,
          :changeDescription,
          :informationRequested,
        ).to_h
      end

      def validate_guest_submission
        # Rate limiting
        ip = request.remote_ip
        cache_key = "guest_submission:#{ip}:#{Time.current.hour}"
        count = Rails.cache.read(cache_key) || 0

        if count >= 10
          render json: { error: 'Too many submissions. Please try again later.' }, status: :too_many_requests
          return
        end

        Rails.cache.write(cache_key, count + 1, expires_in: 1.hour)
      end

      def handle_attachment
        attachment = guest_ticket_params[:attachment]
        if attachment.present? && attachment.is_a?(ActionDispatch::Http::UploadedFile)
          GuestTicketAttachment.create(
            guest_ticket: @guest_ticket,
            original_filename: attachment.original_filename,
            file: attachment,
          )
        end
      end

      def send_confirmation_email
        GuestTicketMailer.with(guest_ticket: @guest_ticket).confirmation_email.deliver_later
      end

      def notify_approver
        approver_email = @guest_ticket.specific_data.dig('change_request', 'approverEmail')
        if approver_email.present?
          GuestTicketMailer.with(guest_ticket: @guest_ticket, approver_email:).approver_notification.deliver_later
        end
      end

      def route_service_request
        request_type = @guest_ticket.specific_data.dig('service_request', 'requestType')
        # Route to appropriate team based on request type
        case request_type
        when 'password_reset'
          notify_it_support
        when 'starter_form'
          notify_hr_team
        when 'leaver_form'
          notify_hr_team
        when 'transfer_form'
          notify_hr_team
        when 'information_request'
          notify_management
        end
      end

      def notify_it_support
        # Implementation for notifying IT support
      end

      def notify_hr_team
        # Implementation for notifying HR team
      end

      def notify_management
        # Implementation for notifying management
      end

      def build_service_request_description(service_data)
        case service_data[:requestType]
        when 'password_reset'
          "Password Reset Request\nSystem: #{service_data[:system]}\nLogin: #{service_data[:login]}"
        when 'starter_form'
          "Starter Form\nName: #{service_data[:firstName]} #{service_data[:lastName]}\nAccess Needs:\n#{service_data[:accessNeeds]}"
        when 'leaver_form'
          "Leaver Form\nEmployee: #{service_data[:employeeId]}\nType: #{service_data[:departureType]}"
        when 'transfer_form'
          "Transfer Form\nEmployee: #{service_data[:employeeId]}\nChanges:\n#{service_data[:changeDescription]}"
        when 'information_request'
          "Information Request\n#{service_data[:informationRequested]}"
        end
      end
    end
  end
end
