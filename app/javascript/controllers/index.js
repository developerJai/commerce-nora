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
import ProductGalleryController from "controllers/product_gallery_controller"
import ProductVariantController from "controllers/product_variant_controller"
import TabsController from "controllers/tabs_controller"
import QuantityController from "controllers/quantity_controller"
import ImagePreviewController from "controllers/image_preview_controller"
import MultiImagePreviewController from "controllers/multi_image_preview_controller"
import CollectionItemPreviewController from "controllers/collection_item_preview_controller"
import CaptchaController from "controllers/captcha_controller"
import PriceValidationController from "controllers/price_validation_controller"
import ProductPageController from "controllers/product_page_controller"
import SmartAppBannerController from "controllers/smart_app_banner_controller"
import MobileAppSectionController from "controllers/mobile_app_section_controller"
import CouponCelebrationController from "controllers/coupon_celebration_controller"
import MobileSearchController from "controllers/mobile_search_controller"
import MobileSearchTriggerController from "controllers/mobile_search_trigger_controller"

application.register("sidebar", SidebarController)
application.register("dropdown", DropdownController)
application.register("flash", FlashController)
application.register("cart", CartController)
application.register("variant-selector", VariantSelectorController)
application.register("modal", ModalController)
application.register("search-autocomplete", SearchAutocompleteController)
application.register("cart-controls", CartControlsController)
application.register("draft-order", DraftOrderController)
application.register("product-gallery", ProductGalleryController)
application.register("product-variant", ProductVariantController)
application.register("product-page", ProductPageController)
application.register("tabs", TabsController)
application.register("quantity", QuantityController)
application.register("image-preview", ImagePreviewController)
application.register("multi-image-preview", MultiImagePreviewController)
application.register("collection-item-preview", CollectionItemPreviewController)
application.register("captcha", CaptchaController)
application.register("price-validation", PriceValidationController)
application.register("smart-app-banner", SmartAppBannerController)
application.register("mobile-app-section", MobileAppSectionController)
application.register("coupon-celebration", CouponCelebrationController)
application.register("mobile-search", MobileSearchController)
application.register("mobile-search-trigger", MobileSearchTriggerController)
