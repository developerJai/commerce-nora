module Admin
  class TicketMessagesController < BaseController
    before_action :set_ticket

    def create
      @ticket.add_message(sender: current_admin, body: ticket_message_params[:body])
      redirect_to admin_support_ticket_path(@ticket), notice: "Reply sent"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_support_ticket_path(@ticket), alert: e.record.errors.full_messages.join(", ")
    end

    private

    def set_ticket
      @ticket = SupportTicket.find_by!(ticket_number: params[:support_ticket_ticket_number])
    end

    def ticket_message_params
      params.require(:ticket_message).permit(:body)
    end
  end
end
