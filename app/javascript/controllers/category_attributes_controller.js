import { Controller } from "@hotwired/stimulus"

// Loads dynamic attribute fields when the category select changes.
// Fetches product + variant attribute partials from the server based
// on the selected category's attribute_config.
export default class extends Controller {
  static targets = ["categorySelect", "productAttributes", "variantAttributes"]
  static values = { url: String, productId: String }

  connect() {
    // Load attributes if a category is already selected (e.g. edit form)
    if (this.categorySelectTarget.value) {
      this.loadAttributes()
    }
  }

  categoryChanged() {
    this.loadAttributes()
  }

  async loadAttributes() {
    const categoryId = this.categorySelectTarget.value
    if (!categoryId) {
      // No category selected — clear attribute sections
      if (this.hasProductAttributesTarget) {
        this.productAttributesTarget.innerHTML = this.emptyState("Select a category to see relevant product attributes")
      }
      if (this.hasVariantAttributesTarget) {
        this.variantAttributesTarget.innerHTML = this.emptyState("Select a category to see relevant variant attributes")
      }
      return
    }

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("category_id", categoryId)
    if (this.productIdValue) {
      url.searchParams.set("product_id", this.productIdValue)
    }

    try {
      const response = await fetch(url, {
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const html = await response.text()
        // The response contains both product and variant attribute sections
        // wrapped in identifiable divs
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")

        const productSection = doc.getElementById("dynamic-product-attributes")
        const variantSection = doc.getElementById("dynamic-variant-attributes")

        if (this.hasProductAttributesTarget && productSection) {
          this.productAttributesTarget.innerHTML = productSection.innerHTML
        }
        if (this.hasVariantAttributesTarget && variantSection) {
          this.variantAttributesTarget.innerHTML = variantSection.innerHTML
        }
      }
    } catch (error) {
      console.error("Failed to load attribute fields:", error)
    }
  }

  emptyState(message) {
    return `<p class="text-sm text-gray-400 italic py-2">${message}</p>`
  }
}
