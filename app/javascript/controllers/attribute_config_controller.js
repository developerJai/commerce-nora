import { Controller } from "@hotwired/stimulus"

// Visual editor for category attribute_config JSONB.
// Manages product_attributes and variant_attributes with add/remove,
// preset templates, and serializes to a hidden field on submit.
export default class extends Controller {
  static targets = [
    "hiddenField",
    "presetSelect",
    "productSection",
    "variantSection",
    "emptyProduct",
    "emptyVariant"
  ]

  // ── Preset templates ──────────────────────────────────────────────
  static PRESETS = {
    jewellery: {
      product_attributes: {
        base_material: {
          label: "Base Material", required: true,
          options: ["Sterling Silver","925 Silver","Gold","Rose Gold","Brass","Alloy","Platinum","Copper","Stainless Steel","German Silver","White Metal","Panchdhatu","Bronze","Zinc","Iron"]
        },
        plating: {
          label: "Plating", required: false,
          options: ["Gold Plated","22K Gold Plated","18K Gold Plated","Rose Gold Plated","Rhodium Plated","Silver Plated","Black Rhodium","Two-Tone","Oxidised","Antique Gold","Antique Silver","Matte Finish","Micron Gold","None"]
        },
        gemstone: {
          label: "Gemstone / Stone Type", required: false,
          options: ["Diamond","Lab-Grown Diamond","Pearl","Ruby","Emerald","Sapphire","Cubic Zirconia (CZ)","American Diamond (AD)","Moissanite","Topaz","Amethyst","Garnet","Opal","Turquoise","Kundan","Polki","Meenakari","Zircon","Crystal","Swarovski Crystal","Glass Stone","Semi-Precious Stone","Onyx","Agate","Lapis Lazuli","Coral","Cat's Eye","Moon Stone","Tiger Eye","Navratna","Temple Stone","None"]
        },
        occasion: {
          label: "Occasion", required: false,
          options: ["Wedding","Engagement","Party","Casual","Festive","Traditional","Office Wear","Anniversary","Daily Wear","Bridal","Puja","Haldi","Mehendi","Sangeet"]
        },
        ideal_for: {
          label: "Ideal For", required: false,
          options: ["Women","Men","Girls","Boys","Unisex","Couples"]
        },
        country_of_origin: {
          label: "Country of Origin", required: false, options: [], default: "India"
        }
      },
      variant_attributes: {
        color: {
          label: "Color", required: false,
          options: ["Gold","Silver","Rose Gold","White","Black","Green","Red","Blue","Pink","Multi","Oxidised","Antique Gold","Copper","Two-Tone","Yellow","Brown"]
        },
        size: {
          label: "Size", required: false,
          options: ["Free Size","Adjustable"]
        }
      }
    },

    clothing: {
      product_attributes: {
        fabric_type: {
          label: "Fabric Type", required: true,
          options: ["Silk","Pure Silk","Banarasi Silk","Kanjivaram Silk","Cotton","Pure Cotton","Cotton Blend","Georgette","Chiffon","Crepe","Net","Organza","Satin","Velvet","Linen","Rayon","Lycra","Jacquard"]
        },
        pattern: {
          label: "Pattern / Work", required: false,
          options: ["Zari Work","Embroidery","Sequin Work","Mirror Work","Block Print","Bandhani","Kalamkari","Ikat","Patola","Leheriya","Phulkari","Chikankari","Gota Patti","Thread Work","Stone Work","Plain"]
        },
        occasion: {
          label: "Occasion", required: false,
          options: ["Wedding","Festive","Casual","Party","Daily Wear","Puja","Traditional","Formal"]
        },
        ideal_for: {
          label: "Ideal For", required: false,
          options: ["Women","Men","Girls","Boys","Unisex"]
        },
        country_of_origin: {
          label: "Country of Origin", required: false, options: [], default: "India"
        }
      },
      variant_attributes: {
        color: {
          label: "Color", required: false,
          options: ["Red","Blue","Green","Yellow","Pink","Purple","Orange","White","Black","Maroon","Navy Blue","Magenta","Teal","Peach","Cream","Beige","Gold","Silver","Multi"]
        },
        size: {
          label: "Size", required: false,
          options: ["Free Size","XS","S","M","L","XL","XXL","XXXL","32","34","36","38","40","42","44","46"]
        }
      }
    },

    gifts: {
      product_attributes: {
        gift_type: {
          label: "Gift Type", required: false,
          options: ["Jewellery Set","Gift Box","Hamper","Personalised","Combo Set","Pooja Thali","Return Gift","Corporate Gift"]
        },
        occasion: {
          label: "Occasion", required: false,
          options: ["Birthday","Anniversary","Wedding","Diwali","Raksha Bandhan","Karva Chauth","Valentine's Day","Mother's Day","Housewarming","Thank You","Festival","Any Occasion"]
        },
        ideal_for: {
          label: "Ideal For", required: false,
          options: ["Women","Men","Girls","Boys","Couples","Family","Anyone"]
        },
        country_of_origin: {
          label: "Country of Origin", required: false, options: [], default: "India"
        }
      },
      variant_attributes: {
        color: {
          label: "Color", required: false,
          options: ["Gold","Silver","Rose Gold","Multi","Red","Blue","Green","Pink","White","Black"]
        },
        size: {
          label: "Size / Variant", required: false,
          options: ["Standard","Small","Medium","Large"]
        }
      }
    }
  }

  connect() {
    // Load existing config into the visual editor
    const existing = this.hiddenFieldTarget.value
    if (existing && existing.trim() !== "" && existing !== "{}") {
      try {
        const config = JSON.parse(existing)
        this.renderConfig(config)
      } catch {
        // Invalid JSON — start empty
      }
    }
  }

  // ── Preset selection ──────────────────────────────────────────────
  applyPreset() {
    const key = this.presetSelectTarget.value
    if (!key) return

    const preset = this.constructor.PRESETS[key]
    if (!preset) return

    if (this.hasAttributes()) {
      if (!confirm("This will replace the current configuration with the preset. Continue?")) {
        this.presetSelectTarget.value = ""
        return
      }
    }

    this.renderConfig(preset)
    this.serialize()
    this.presetSelectTarget.value = ""
  }

  hasAttributes() {
    return this.productSectionTarget.querySelectorAll("[data-attr-card]").length > 0 ||
           this.variantSectionTarget.querySelectorAll("[data-attr-card]").length > 0
  }

  // ── Render full config ────────────────────────────────────────────
  renderConfig(config) {
    this.productSectionTarget.innerHTML = ""
    this.variantSectionTarget.innerHTML = ""

    const pa = config.product_attributes || {}
    Object.entries(pa).forEach(([key, def]) => {
      this.productSectionTarget.appendChild(this.buildAttrCard(key, def, "product"))
    })

    const va = config.variant_attributes || {}
    Object.entries(va).forEach(([key, def]) => {
      this.variantSectionTarget.appendChild(this.buildAttrCard(key, def, "variant"))
    })

    this.toggleEmptyStates()
  }

  // ── Build a single attribute card ─────────────────────────────────
  buildAttrCard(key, def, scope) {
    const card = document.createElement("div")
    card.dataset.attrCard = ""
    card.dataset.scope = scope
    card.className = "border border-gray-200 rounded-lg p-4 space-y-3 bg-gray-50"

    card.innerHTML = `
      <div class="flex items-start justify-between gap-3">
        <div class="flex-1 grid grid-cols-2 gap-3">
          <div>
            <label class="block text-xs font-medium text-gray-500 mb-1">Attribute Key</label>
            <input type="text" data-field="key" value="${this.esc(key)}"
                   class="w-full px-3 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                   placeholder="e.g. base_material">
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-500 mb-1">Display Label</label>
            <input type="text" data-field="label" value="${this.esc(def.label || "")}"
                   class="w-full px-3 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                   placeholder="e.g. Base Material">
          </div>
        </div>
        <button type="button" data-action="click->attribute-config#removeAttr"
                class="mt-5 p-1.5 text-red-400 hover:text-red-600 hover:bg-red-50 rounded-md transition" title="Remove attribute">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
        </button>
      </div>

      <div class="flex items-center gap-4">
        <label class="flex items-center gap-1.5 text-sm">
          <input type="checkbox" data-field="required" ${def.required ? "checked" : ""}
                 class="h-3.5 w-3.5 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500">
          <span class="text-gray-600">Required</span>
        </label>
        ${def.default !== undefined ? `
        <div class="flex items-center gap-1.5">
          <label class="text-xs text-gray-500">Default:</label>
          <input type="text" data-field="default" value="${this.esc(def.default || "")}"
                 class="px-2 py-1 text-xs border border-gray-300 rounded-md w-24 focus:ring-indigo-500 focus:border-indigo-500">
        </div>` : ""}
      </div>

      <div>
        <div class="flex items-center justify-between mb-1.5">
          <label class="text-xs font-medium text-gray-500">Options</label>
          <button type="button" data-action="click->attribute-config#addOption"
                  class="inline-flex items-center gap-1 px-2 py-0.5 text-xs font-medium text-indigo-600 hover:text-indigo-800 hover:bg-indigo-50 rounded transition">
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            Add
          </button>
        </div>
        <div data-options-list class="flex flex-wrap gap-1.5">
          ${(def.options || []).map(opt => this.buildOptionTag(opt)).join("")}
        </div>
      </div>
    `

    // Wire up change events for auto-serialization
    card.querySelectorAll("input").forEach(input => {
      input.addEventListener("change", () => this.serialize())
      input.addEventListener("blur", () => this.serialize())
    })

    return card
  }

  buildOptionTag(value) {
    return `<span class="inline-flex items-center gap-1 px-2.5 py-1 bg-white border border-gray-200 rounded-full text-xs text-gray-700 group hover:border-red-300 transition">
      <input type="text" data-option-value value="${this.esc(value)}"
             class="bg-transparent border-none p-0 text-xs text-gray-700 w-auto focus:ring-0 focus:outline-none"
             style="width: ${Math.max(value.length * 7, 30)}px"
             onInput="this.style.width = Math.max(this.value.length * 7, 30) + 'px'">
      <button type="button" data-action="click->attribute-config#removeOption"
              class="text-gray-300 hover:text-red-500 transition" title="Remove">
        <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/></svg>
      </button>
    </span>`
  }

  // ── Actions ───────────────────────────────────────────────────────

  addProductAttr() {
    const card = this.buildAttrCard("", { label: "", required: false, options: [] }, "product")
    this.productSectionTarget.appendChild(card)
    this.toggleEmptyStates()
    card.querySelector("[data-field='key']").focus()
    this.serialize()
  }

  addVariantAttr() {
    const card = this.buildAttrCard("", { label: "", required: false, options: [] }, "variant")
    this.variantSectionTarget.appendChild(card)
    this.toggleEmptyStates()
    card.querySelector("[data-field='key']").focus()
    this.serialize()
  }

  removeAttr(event) {
    const card = event.target.closest("[data-attr-card]")
    if (card) {
      card.remove()
      this.toggleEmptyStates()
      this.serialize()
    }
  }

  addOption(event) {
    const card = event.target.closest("[data-attr-card]")
    const list = card.querySelector("[data-options-list]")
    const html = this.buildOptionTag("")
    const temp = document.createElement("div")
    temp.innerHTML = html
    const tag = temp.firstElementChild
    list.appendChild(tag)
    const input = tag.querySelector("[data-option-value]")
    input.focus()
    input.addEventListener("change", () => this.serialize())
    input.addEventListener("blur", () => this.serialize())
  }

  removeOption(event) {
    const tag = event.target.closest("span")
    if (tag) {
      tag.remove()
      this.serialize()
    }
  }

  // ── Serialization ─────────────────────────────────────────────────

  serialize() {
    const config = { product_attributes: {}, variant_attributes: {} }

    this.productSectionTarget.querySelectorAll("[data-attr-card]").forEach(card => {
      const entry = this.readCard(card)
      if (entry.key) config.product_attributes[entry.key] = entry.def
    })

    this.variantSectionTarget.querySelectorAll("[data-attr-card]").forEach(card => {
      const entry = this.readCard(card)
      if (entry.key) config.variant_attributes[entry.key] = entry.def
    })

    this.hiddenFieldTarget.value = JSON.stringify(config)
  }

  readCard(card) {
    const key = (card.querySelector("[data-field='key']")?.value || "").trim().toLowerCase().replace(/\s+/g, "_")
    const label = (card.querySelector("[data-field='label']")?.value || "").trim()
    const required = card.querySelector("[data-field='required']")?.checked || false
    const defaultField = card.querySelector("[data-field='default']")
    const options = Array.from(card.querySelectorAll("[data-option-value]"))
      .map(el => el.value.trim())
      .filter(v => v !== "")

    const def = { label, required, options }
    if (defaultField && defaultField.value.trim() !== "") {
      def.default = defaultField.value.trim()
    }

    return { key, def }
  }

  // ── Helpers ───────────────────────────────────────────────────────

  toggleEmptyStates() {
    const hasProd = this.productSectionTarget.querySelectorAll("[data-attr-card]").length > 0
    const hasVar = this.variantSectionTarget.querySelectorAll("[data-attr-card]").length > 0

    if (this.hasEmptyProductTarget) {
      this.emptyProductTarget.classList.toggle("hidden", hasProd)
    }
    if (this.hasEmptyVariantTarget) {
      this.emptyVariantTarget.classList.toggle("hidden", hasVar)
    }
  }

  esc(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML.replace(/"/g, "&quot;")
  }
}
