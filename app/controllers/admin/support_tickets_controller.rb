module Admin
  class SupportTicketsController < BaseController
    before_action :set_ticket, only: [:show, :edit, :update, :destroy, :resolve, :close, :reopen]

    def index
      @status = params[:status]
      @priority = params[:priority]
      @unread = params[:unread]

      tickets = SupportTicket.includes(:customer, :order).recent
      tickets = tickets.by_status(@status) if @status.present?
      tickets = tickets.by_priority(@priority) if @priority.present?
      tickets = tickets.unread_for_admin if @unread.present?

      @pagy, @support_tickets = pagy(tickets, limit: 20)
    end

    def show
      @messages = @support_ticket.ticket_messages.includes(:sender).recent
      @support_ticket.update_column(:admin_last_seen_at, Time.current)
    end

    def edit
    end

    def update
      if @support_ticket.update(ticket_params)
        redirect_to admin_support_ticket_path(@support_ticket), notice: "Ticket updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @support_ticket.destroy
      redirect_to admin_support_tickets_path, notice: "Ticket deleted"
    end

    def resolve
      @support_ticket.resolve!
      redirect_to admin_support_ticket_path(@support_ticket), notice: "Ticket resolved"
    end

    def close
      @support_ticket.close!
      redirect_to admin_support_ticket_path(@support_ticket), notice: "Ticket closed"
    end

    def reopen
      @support_ticket.reopen!
      redirect_to admin_support_ticket_path(@support_ticket), notice: "Ticket reopened"
    end

    private

    def set_ticket
      @support_ticket = SupportTicket.find_by!(ticket_number: params[:ticket_number])
    end

    def ticket_params
      params.require(:support_ticket).permit(:subject, :status, :priority)
    end
  end
end
