class SupportTicketsController < ApplicationController
  before_action :require_customer
  before_action :set_ticket, only: [:show]

  def index
    @pagy, @tickets = pagy(current_customer.support_tickets.recent.includes(:order), items: 10)
  end

  def show
    @messages = @ticket.ticket_messages.recent.includes(:sender)
  end

  def new
    @ticket = current_customer.support_tickets.build
    @orders = current_customer.orders.placed.recent
  end

  def create
    @ticket = current_customer.support_tickets.build(ticket_params)

    if @ticket.save
      # Add the initial message
      if params[:message].present?
        @ticket.add_message(sender: current_customer, body: params[:message])
      end

      redirect_to support_ticket_path(@ticket), notice: "Support ticket created"
    else
      @orders = current_customer.orders.placed.recent
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_ticket
    @ticket = current_customer.support_tickets.find(params[:id])
  end

  def ticket_params
    params.require(:support_ticket).permit(:subject, :order_id, :priority)
  end
end
