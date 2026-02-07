class CustomerTicketMessagesController < ApplicationController
  before_action :require_customer
  before_action :set_ticket

  def create
    if @ticket.can_reply?
      @ticket.add_message(sender: current_customer, body: params[:body])
      redirect_to support_ticket_path(@ticket), notice: "Reply sent"
    else
      redirect_to support_ticket_path(@ticket), alert: "This ticket is closed"
    end
  end

  private

  def set_ticket
    @ticket = current_customer.support_tickets.find_by!(ticket_number: params[:support_ticket_ticket_number])
  end
end
