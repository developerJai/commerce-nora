module AdminHelper
  def order_status_class(status)
    case status
    when "pending"
      "bg-yellow-100 text-yellow-800"
    when "confirmed"
      "bg-blue-100 text-blue-800"
    when "processing"
      "bg-indigo-100 text-indigo-800"
    when "shipped"
      "bg-purple-100 text-purple-800"
    when "delivered"
      "bg-green-100 text-green-800"
    when "cancelled"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def payment_status_class(status)
    case status
    when "pending"
      "bg-yellow-100 text-yellow-800"
    when "paid"
      "bg-green-100 text-green-800"
    when "failed"
      "bg-red-100 text-red-800"
    when "refunded"
      "bg-purple-100 text-purple-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def refund_status_class(status)
    case status
    when "not_refunded"
      "bg-gray-100 text-gray-800"
    when "initiated"
      "bg-yellow-100 text-yellow-800"
    when "paid"
      "bg-green-100 text-green-800"
    when "failed"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def ticket_status_class(status)
    case status
    when "open"
      "bg-yellow-100 text-yellow-800"
    when "in_progress"
      "bg-blue-100 text-blue-800"
    when "resolved"
      "bg-green-100 text-green-800"
    when "closed"
      "bg-gray-100 text-gray-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  # Alias for views
  alias_method :ticket_status_badge_class, :ticket_status_class

  def priority_class(priority)
    case priority
    when "low"
      "bg-gray-100 text-gray-800"
    when "normal"
      "bg-blue-100 text-blue-800"
    when "high"
      "bg-orange-100 text-orange-800"
    when "urgent"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  # Alias for views
  alias_method :priority_badge_class, :priority_class

  def status_badge_class(status)
    case status
    when "pending"
      "bg-yellow-100 text-yellow-800"
    when "paid"
      "bg-green-100 text-green-800"
    when "failed"
      "bg-red-100 text-red-800"
    when "refunded"
      "bg-purple-100 text-purple-800"
    when "partially_refunded"
      "bg-orange-100 text-orange-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end
