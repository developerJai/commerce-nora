module Admin
  class TicketMessagesController < BaseController
    before_action :set_ticket

    def create
      @message = @ticket.add_message(sender: current_admin, body: params[:body])

      if @message.persisted?
        redirect_to admin_support_ticket_path(@ticket), notice: "Reply sent"
      else
        redirect_to admin_support_ticket_path(@ticket), alert: "Failed to send reply"
      end
    end

    private

    def set_ticket
      @ticket = SupportTicket.find(params[:support_ticket_id])
    end
  end
end
