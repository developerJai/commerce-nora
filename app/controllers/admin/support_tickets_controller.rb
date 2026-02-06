module Admin
  class SupportTicketsController < BaseController
    before_action :set_ticket, only: [:show, :edit, :update, :destroy, :resolve, :close, :reopen]

    def index
      @status = params[:status]
      @priority = params[:priority]

      tickets = SupportTicket.includes(:customer, :order).recent
      tickets = tickets.by_status(@status) if @status.present?
      tickets = tickets.by_priority(@priority) if @priority.present?

      @pagy, @support_tickets = pagy(tickets, limit: 20)
    end

    def show
      @messages = @ticket.ticket_messages.includes(:sender).recent
    end

    def edit
    end

    def update
      if @ticket.update(ticket_params)
        redirect_to admin_support_ticket_path(@ticket), notice: "Ticket updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @ticket.destroy
      redirect_to admin_support_tickets_path, notice: "Ticket deleted"
    end

    def resolve
      @ticket.resolve!
      redirect_to admin_support_ticket_path(@ticket), notice: "Ticket resolved"
    end

    def close
      @ticket.close!
      redirect_to admin_support_ticket_path(@ticket), notice: "Ticket closed"
    end

    def reopen
      @ticket.reopen!
      redirect_to admin_support_ticket_path(@ticket), notice: "Ticket reopened"
    end

    private

    def set_ticket
      @ticket = SupportTicket.find(params[:id])
    end

    def ticket_params
      params.require(:support_ticket).permit(:subject, :status, :priority)
    end
  end
end
