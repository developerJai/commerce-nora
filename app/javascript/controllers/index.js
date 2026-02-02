// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Import custom controllers
import SidebarController from "controllers/sidebar_controller"
import DropdownController from "controllers/dropdown_controller"
import FlashController from "controllers/flash_controller"
import CartController from "controllers/cart_controller"
import VariantSelectorController from "controllers/variant_selector_controller"
import ModalController from "controllers/modal_controller"
import SearchAutocompleteController from "controllers/search_autocomplete_controller"
import CartControlsController from "controllers/cart_controls_controller"
import DraftOrderController from "controllers/draft_order_controller"

application.register("sidebar", SidebarController)
application.register("dropdown", DropdownController)
application.register("flash", FlashController)
application.register("cart", CartController)
application.register("variant-selector", VariantSelectorController)
application.register("modal", ModalController)
application.register("search-autocomplete", SearchAutocompleteController)
application.register("cart-controls", CartControlsController)
application.register("draft-order", DraftOrderController)
