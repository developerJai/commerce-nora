module Admin
  class SupportTicketsController < BaseController
    before_action :set_ticket, only: [:show, :edit, :update, :destroy, :resolve, :close, :reopen]
    before_action :require_admin_role!, only: [:edit, :update, :destroy]

    def index
      @status = params[:status]
      @priority = params[:priority]
      @unread = params[:unread]
      @vendor_id = params[:vendor_id]

      tickets = if vendor_context?
        SupportTicket.for_vendor(current_vendor)
      else
        SupportTicket.all
      end

      if admin_role? && !vendor_context? && @vendor_id.present?
        tickets = tickets.for_vendor(Vendor.find_by(id: @vendor_id))
      end

      tickets = tickets.by_priority(@priority) if @priority.present?

      @ticket_counts = {
        all: tickets.count,
        open: tickets.where(status: 'open').count,
        in_progress: tickets.where(status: 'in_progress').count,
        resolved: tickets.where(status: 'resolved').count,
        closed: tickets.where(status: 'closed').count
      }
      @unread_count = tickets.unread_for_admin.count

      tickets = tickets.includes(:customer, :order).recent
      tickets = tickets.by_status(@status) if @status.present?
      tickets = tickets.unread_for_admin if @unread.present?

      @pagy, @support_tickets = pagy(tickets, limit: 20)

      if admin_role? && !vendor_context?
        @vendors = Vendor.ordered
      end
    end

    def show
      @messages = @support_ticket.ticket_messages.includes(:sender).recent
      @support_ticket.update_column(:admin_last_seen_at, Time.current)
    end

    # Vendor can create a support ticket to admin
    def new
      return redirect_to(admin_root_path, alert: "Access denied") unless vendor_role?
      @support_ticket = SupportTicket.new
    end

    def create
      return redirect_to(admin_root_path, alert: "Access denied") unless vendor_role?

      @support_ticket = SupportTicket.new(
        vendor: current_vendor,
        subject: params[:support_ticket][:subject],
        priority: params[:support_ticket][:priority] || 'normal',
        status: 'open'
      )

      if @support_ticket.save
        if params[:message].present?
          @support_ticket.add_message(sender: current_admin, body: params[:message])
        end
        redirect_to admin_support_ticket_path(@support_ticket), notice: "Support ticket created"
      else
        render :new, status: :unprocessable_entity
      end
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
      @support_ticket = if vendor_context?
        SupportTicket.for_vendor(current_vendor).find_by!(ticket_number: params[:ticket_number])
      else
        SupportTicket.find_by!(ticket_number: params[:ticket_number])
      end
    end

    def ticket_params
      params.require(:support_ticket).permit(:subject, :status, :priority)
    end
  end
end
