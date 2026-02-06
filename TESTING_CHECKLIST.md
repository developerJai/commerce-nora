# Auracraft - Testing Checklist

## Date: February 6, 2026

This checklist covers all the newly implemented features and pages. Use this to verify that everything works correctly.

---

## ✅ Wishlist Management

### Wishlist Page (`/wishlists`)
- [ ] Page loads without errors
- [ ] Shows account sidebar navigation with correct active state
- [ ] Displays customer photo/initial and name
- [ ] Shows wishlist item count in sidebar
- [ ] Lists all wishlist items with product details
- [ ] Each item shows: product image, name, price, stock status
- [ ] "View Details" button works for each product
- [ ] "Add to Cart" button works for in-stock items
- [ ] Remove button shows confirmation dialog
- [ ] "Clear Wishlist" button shows confirmation dialog
- [ ] Empty state shows when wishlist is empty
- [ ] "Browse Products" link works in empty state

### Add to Wishlist
- [ ] "Add to Wishlist" button works on product pages
- [ ] Button changes to "In Wishlist" when product is added
- [ ] Success message displays after adding
- [ ] Product appears in wishlist immediately
- [ ] Cannot add same product twice (validation works)
- [ ] Login required for adding items

### Remove from Wishlist
- [ ] "In Wishlist" button shows remove confirmation on product pages
- [ ] Remove button on wishlist page works
- [ ] Confirmation dialog appears before removal
- [ ] Success message displays after removal
- [ ] Product disappears from wishlist immediately
- [ ] Button changes back to "Add to Wishlist" on product page

### Wishlist Integration
- [ ] Wishlist count shows in header navigation
- [ ] Wishlist count updates when items are added/removed
- [ ] Wishlist link works in account dropdown
- [ ] Wishlist link works in footer
- [ ] Wishlist link works in mobile navigation
- [ ] "In Wishlist" badge shows on product cards
- [ ] Wishlist count shows in account sidebar

---

## ✅ Address Management

### Index Page (`/addresses`)
- [ ] Page loads without errors
- [ ] Displays "Add New Address" button
- [ ] Shows account sidebar navigation with correct active state
- [ ] Lists all customer addresses
- [ ] Default addresses show "Default Shipping/Billing" badge
- [ ] Non-default addresses show type badge
- [ ] Each address shows: name, full address, phone (if present)
- [ ] Edit button works for each address
- [ ] Delete button shows confirmation dialog
- [ ] Empty state shows when no addresses exist

### New Address Page (`/addresses/new`)
- [ ] Page loads without errors
- [ ] Breadcrumb navigation is correct
- [ ] Form displays all required fields
- [ ] Address type radio buttons work (Shipping/Billing)
- [ ] All form fields accept input
- [ ] Country field defaults to "India"
- [ ] "Set as default" checkbox works
- [ ] Validation errors display properly
- [ ] Success: Redirects to addresses list with notice
- [ ] Cancel button returns to addresses list

### Edit Address Page (`/addresses/:id/edit`)
- [ ] Page loads without errors
- [ ] Breadcrumb navigation is correct
- [ ] Form pre-fills with existing address data
- [ ] Can modify all fields
- [ ] Can change default status
- [ ] Validation errors display properly
- [ ] Success: Redirects to addresses list with notice
- [ ] Cancel button returns to addresses list

### Address Deletion
- [ ] Delete button shows confirmation dialog
- [ ] Confirming deletion removes address
- [ ] Success message displays
- [ ] Redirects to addresses list

---

## ✅ Order Reviews

### Review Form (`/orders/:id/reviews/new`)
- [ ] Accessible only from delivered orders
- [ ] Shows product information (image, name, order number)
- [ ] 5-star rating selector works
- [ ] Clicking stars updates selection
- [ ] Rating is required (form validation)
- [ ] Review title field works
- [ ] Review body textarea works
- [ ] Character count guidance visible
- [ ] Cancel button returns to order page
- [ ] Submit creates review
- [ ] Success: Redirects to order with notice
- [ ] Validation errors display properly

### Review Display
- [ ] Reviews appear on product detail pages
- [ ] Shows star rating, title, body
- [ ] Shows customer name and date
- [ ] Admin responses display (if present)
- [ ] Empty state shows when no reviews
- [ ] Average rating displays correctly

---

## ✅ Account Profile Management

### Edit Profile (`/account/edit`)
- [ ] Page loads without errors
- [ ] Breadcrumb navigation works
- [ ] Form pre-fills with customer data
- [ ] Can edit first name, last name
- [ ] Can edit email address
- [ ] Can edit phone number
- [ ] Info box links to password change page
- [ ] Validation errors display
- [ ] Success: Redirects to account page with notice
- [ ] Cancel returns to account page

### Change Password (`/account/password/edit`)
- [ ] Page loads without errors
- [ ] Breadcrumb navigation works
- [ ] Current password field required
- [ ] New password field required (min 6 chars)
- [ ] Password confirmation field required
- [ ] Password mismatch shows error
- [ ] Incorrect current password shows error
- [ ] Security tips displayed
- [ ] Success: Redirects to account page with notice
- [ ] Cancel returns to account page

---

## ✅ Static Pages

### Shipping Page (`/shipping`)
- [ ] Page loads without errors
- [ ] Free shipping policy explained
- [ ] Delivery times for different areas listed
- [ ] Order processing information displayed
- [ ] Tracking information provided
- [ ] International shipping status noted
- [ ] Contact support link works

### Returns & Exchange Page (`/returns`)
- [ ] Page loads without errors
- [ ] 30-day money-back guarantee explained
- [ ] Lifetime exchange policy detailed
- [ ] Return conditions listed
- [ ] How-to steps provided
- [ ] Refund process explained
- [ ] Non-returnable items listed
- [ ] Contact support link works

### About Page (`/about`)
- [ ] Page loads without errors
- [ ] Company story displayed
- [ ] Values section with icons shows
- [ ] Commitment section displayed
- [ ] Contact CTA buttons work
- [ ] "Shop Now" link goes to products
- [ ] "Contact Us" link goes to support

### Privacy Policy (`/privacy`)
- [ ] Page loads without errors
- [ ] Last updated date shows current date
- [ ] All sections display properly
- [ ] Information collection section clear
- [ ] Usage explanation provided
- [ ] Cookie policy explained
- [ ] User rights listed
- [ ] Contact support link works

### Terms & Conditions (`/terms`)
- [ ] Page loads without errors
- [ ] Last updated date shows current date
- [ ] All 13 sections display
- [ ] Use of website terms clear
- [ ] Account registration rules listed
- [ ] Product/pricing info provided
- [ ] Order/payment terms explained
- [ ] Shipping/returns linked
- [ ] Contact information displayed

---

## ✅ Navigation & Links

### Header Navigation
- [ ] Logo links to home
- [ ] Search bar works
- [ ] Account dropdown functions
- [ ] Cart link displays item count
- [ ] Wishlist link displays item count (when logged in)
- [ ] All category links work
- [ ] "Collections" link works
- [ ] No broken links in header

### Footer Links
- [ ] All "Shop" links work
  - [ ] All Jewellery → /products
  - [ ] New Arrivals → /products?sort=newest
  - [ ] Best Sellers → /products?featured=true
- [ ] All "Account" links work
  - [ ] My Account → /account
  - [ ] Orders → /orders
  - [ ] Addresses → /addresses
  - [ ] Wishlist → /wishlists
- [ ] All "Help" links work
  - [ ] Contact Us → /support_tickets
  - [ ] Shipping → /shipping
  - [ ] Returns & Exchange → /returns
- [ ] All "Company" links work
  - [ ] About Us → /about
  - [ ] Privacy Policy → /privacy
  - [ ] Terms & Conditions → /terms

### Mobile Navigation
- [ ] Bottom nav bar visible on mobile
- [ ] Home icon links to /
- [ ] Shop icon links to /products
- [ ] Bag icon links to /cart
- [ ] Orders icon links to /orders
- [ ] Account icon links correctly

---

## ✅ Account Sidebar

Pages with sidebar: `/account`, `/addresses`, `/orders`, `/support_tickets`, `/wishlists`

- [ ] Sidebar displays customer photo/initial
- [ ] Shows customer name and email
- [ ] Profile link works
- [ ] Orders link works
- [ ] Addresses link works
- [ ] Wishlist link works
- [ ] Support link works
- [ ] Active page highlighted correctly

---

## ✅ Breadcrumbs

Check breadcrumbs on:
- [ ] `/addresses/new` (Account → Addresses → Add New)
- [ ] `/addresses/:id/edit` (Account → Addresses → Edit)
- [ ] `/account/edit` (Account → Edit Profile)
- [ ] `/account/password/edit` (Account → Change Password)
- [ ] `/orders/:id/reviews/new` (Orders → Order# → Write Review)

All should:
- [ ] Display correct path
- [ ] All intermediate links work
- [ ] Current page not clickable

---

## ✅ Forms & Validation

### General Form Testing
- [ ] All required field validations work
- [ ] Error messages display clearly
- [ ] Field focus states work
- [ ] Submit buttons show loading states (if applicable)
- [ ] Cancel/back buttons work
- [ ] Form remembers data on validation error

### Specific Form Tests
- [ ] Address form validates all required fields
- [ ] Email validation works on profile edit
- [ ] Password length validation works
- [ ] Phone number accepts proper formats
- [ ] Rating selection required on reviews

---

## ✅ Responsive Design

Test on different screen sizes:

### Mobile (< 640px)
- [ ] All pages render correctly
- [ ] Forms are usable
- [ ] Buttons are tappable
- [ ] No horizontal scrolling
- [ ] Bottom navigation visible
- [ ] Text is readable

### Tablet (640px - 1024px)
- [ ] Layout adapts appropriately
- [ ] Sidebars display correctly
- [ ] Forms are well-spaced
- [ ] Navigation works properly

### Desktop (> 1024px)
- [ ] Full layout displays
- [ ] Sidebars stick correctly
- [ ] Content is centered
- [ ] No excessive whitespace

---

## ✅ Error Handling

### 404 Errors
- [ ] Invalid address ID → 404
- [ ] Invalid order ID → 404
- [ ] Non-existent pages → 404

### Authorization
- [ ] Addresses pages require login
- [ ] Review pages require login
- [ ] Account pages require login
- [ ] Proper redirect after login

### Validation Errors
- [ ] Display above forms
- [ ] Use clear language
- [ ] Highlight problem fields
- [ ] Don't lose form data

---

## ✅ User Experience

### Success Messages
- [ ] Address created → "Address added successfully"
- [ ] Address updated → "Address updated successfully"
- [ ] Address deleted → "Address deleted"
- [ ] Profile updated → "Account updated successfully"
- [ ] Password changed → "Password updated successfully"
- [ ] Review submitted → "Thank you for your review!"

### Visual Feedback
- [ ] Hover states on buttons/links
- [ ] Active states on navigation
- [ ] Loading indicators (if any)
- [ ] Smooth transitions
- [ ] Icons display correctly

### Accessibility
- [ ] All forms have labels
- [ ] Required fields marked
- [ ] Error messages readable
- [ ] Keyboard navigation works
- [ ] Color contrast sufficient

---

## ✅ Database Operations

### Addresses
- [ ] Create new address
- [ ] Update existing address
- [ ] Delete address
- [ ] Set/unset default address
- [ ] Default per type works correctly

### Reviews
- [ ] Create new review
- [ ] Review linked to order
- [ ] Review linked to product
- [ ] Review linked to customer
- [ ] Duplicate prevention works

### Customer Profile
- [ ] Update customer info
- [ ] Email uniqueness enforced
- [ ] Password encryption works

---

## ✅ Edge Cases

### Addresses
- [ ] Customer with no addresses sees empty state
- [ ] Deleting last address works
- [ ] Changing default updates old default
- [ ] Can have separate shipping/billing defaults

### Reviews
- [ ] Can't review non-delivered orders
- [ ] Can't review same product twice per order
- [ ] Review link only shows for unreviewed products

### Account
- [ ] Can't use duplicate email
- [ ] Wrong current password rejected
- [ ] Password mismatch caught

---

## ✅ Performance

- [ ] Pages load quickly (< 2s)
- [ ] Images load properly
- [ ] No console errors
- [ ] Forms submit without delay
- [ ] Navigation is responsive

---

## Testing Priority

**Critical (Test First):**
1. Address CRUD operations
2. Review submission from orders
3. Profile and password updates
4. All footer links
5. Navigation links

**Important (Test Second):**
1. Static page content
2. Form validations
3. Mobile responsiveness
4. Error handling

**Nice to Have (Test Third):**
1. Visual polish
2. Accessibility features
3. Edge cases
4. Performance tuning

---

## Known Limitations

1. **Wishlist feature not implemented** - Removed from UI
2. **Social media links removed** - Can be added when ready
3. **Static pages use placeholder content** - Update with real policies
4. **No email notifications** - Separate feature to implement

---

## Sign-Off

Once all items are checked:
- [ ] All critical tests passed
- [ ] All important tests passed
- [ ] No major bugs found
- [ ] Ready for production

**Tested by:** _______________
**Date:** _______________
**Notes:** _______________
