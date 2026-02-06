module ApplicationHelper

  def format_price(amount)
    number_to_currency(amount || 0, unit: "₹", format: "%u%n")
  end

  def order_status_badge(status)
    case status
    when 'pending' then 'bg-amber-100 text-amber-800'
    when 'confirmed' then 'bg-sky-100 text-sky-800'
    when 'processing' then 'bg-rose-100 text-rose-800'
    when 'shipped' then 'bg-violet-100 text-violet-800'
    when 'delivered' then 'bg-emerald-100 text-emerald-800'
    when 'cancelled' then 'bg-red-100 text-red-800'
    else 'bg-stone-100 text-stone-800'
    end
  end

  def star_rating(rating, max: 5)
    full_stars = rating.to_i
    half_star = (rating - full_stars) >= 0.5
    empty_stars = max - full_stars - (half_star ? 1 : 0)

    html = ""
    full_stars.times { html += star_icon(:full) }
    html += star_icon(:half) if half_star
    empty_stars.times { html += star_icon(:empty) }
    html.html_safe
  end

  private

  def star_icon(type)
    case type
    when :full
      '<svg class="h-5 w-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>'
    when :half
      '<svg class="h-5 w-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20"><defs><linearGradient id="half"><stop offset="50%" stop-color="currentColor"/><stop offset="50%" stop-color="#D1D5DB"/></linearGradient></defs><path fill="url(#half)" d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>'
    when :empty
      '<svg class="h-5 w-5 text-gray-300" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>'
    end
  end
end
