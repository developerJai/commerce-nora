import { Controller } from "@hotwired/stimulus"

// Loads dynamic attribute fields when the category select changes.
// Fetches product + variant attribute partials from the server based
// on the selected category's attribute_config.
export default class extends Controller {
  static targets = ["categorySelect", "productAttributes", "variantAttributes"]
  static values = { url: String, productId: String }

  connect() {
    // Only auto-load attributes if:
    // 1. A category is selected
    // 2. AND attributes section is empty (not already rendered server-side with values)
    // This prevents overwriting server-rendered values on edit forms
    if (this.categorySelectTarget.value) {
      const hasExistingContent = this.hasProductAttributesTarget && 
        this.productAttributesTarget.querySelectorAll('input, select').length > 0
      
      if (!hasExistingContent) {
        // Small delay to ensure DOM is fully ready, especially after Turbo navigation
        setTimeout(() => this.loadAttributes(), 0)
      }
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

    // Save current form values before reloading to preserve user input
    const savedValues = this.saveCurrentValues()

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

        // Restore previously entered values to preserve user input after validation errors
        this.restoreValues(savedValues)
      }
    } catch (error) {
      console.error("Failed to load attribute fields:", error)
    }
  }

  // Save current input values to preserve them when reloading attributes
  saveCurrentValues() {
    const values = {}
    
    if (this.hasProductAttributesTarget) {
      this.productAttributesTarget.querySelectorAll('input, select').forEach(input => {
        if (input.name && !input.name.includes('__template__')) {
          values[input.name] = input.value
        }
      })
    }
    
    if (this.hasVariantAttributesTarget) {
      this.variantAttributesTarget.querySelectorAll('input, select').forEach(input => {
        if (input.name && !input.name.includes('__template__')) {
          values[input.name] = input.value
        }
      })
    }
    
    return values
  }

  // Restore previously saved input values
  restoreValues(values) {
    Object.entries(values).forEach(([name, value]) => {
      // Try to find input by exact name match
      let input = document.querySelector(`[name="${CSS.escape(name)}"]`)
      
      if (input && value !== undefined && value !== null) {
        if (input.tagName === 'SELECT') {
          // For selects, check if the option exists before setting
          const option = input.querySelector(`option[value="${CSS.escape(value)}"]`)
          if (option) {
            input.value = value
          }
        } else {
          input.value = value
        }
      }
    })
  }

  emptyState(message) {
    return `<p class="text-sm text-gray-400 italic py-2">${message}</p>`
  }
}
