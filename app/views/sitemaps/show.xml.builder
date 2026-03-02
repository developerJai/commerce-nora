xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # Static pages
  @static_pages.each do |page|
    xml.url do
      xml.loc "#{@base_url}#{page[:path]}"
      xml.lastmod Time.current.to_date.iso8601
      xml.changefreq page[:changefreq]
      xml.priority page[:priority]
    end
  end

  # Categories
  @categories.each do |category|
    xml.url do
      xml.loc "#{@base_url}#{category_path(category.slug)}"
      xml.lastmod category.updated_at.to_date.iso8601
      xml.changefreq 'weekly'
      xml.priority 0.8
    end
  end

  # Products
  @products.each do |product|
    xml.url do
      xml.loc "#{@base_url}#{product_path(product.slug)}"
      xml.lastmod product.updated_at.to_date.iso8601
      xml.changefreq 'weekly'
      xml.priority 0.7
    end
  end
end
