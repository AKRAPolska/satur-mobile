---
name: Satur E-Commerce Mobile
colors:
  surface: '#faf8ff'
  surface-dim: '#dad9e1'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3fb'
  surface-container: '#eeedf5'
  surface-container-high: '#e8e7ef'
  surface-container-highest: '#e2e2e9'
  on-surface: '#1a1b21'
  on-surface-variant: '#434652'
  inverse-surface: '#2f3036'
  inverse-on-surface: '#f0f0f8'
  outline: '#747783'
  outline-variant: '#c3c6d3'
  surface-tint: '#315baf'
  primary: '#003684'
  on-primary: '#ffffff'
  primary-container: '#214ea2'
  on-primary-container: '#aec4ff'
  inverse-primary: '#b0c6ff'
  secondary: '#006782'
  on-secondary: '#ffffff'
  secondary-container: '#5fd4fe'
  on-secondary-container: '#005a72'
  tertiary: '#632a00'
  on-tertiary: '#ffffff'
  tertiary-container: '#873c00'
  on-tertiary-container: '#ffb48a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d9e2ff'
  primary-fixed-dim: '#b0c6ff'
  on-primary-fixed: '#001945'
  on-primary-fixed-variant: '#0e4296'
  secondary-fixed: '#bbeaff'
  secondary-fixed-dim: '#5fd4fe'
  on-secondary-fixed: '#001f29'
  on-secondary-fixed-variant: '#004d62'
  tertiary-fixed: '#ffdbc9'
  tertiary-fixed-dim: '#ffb68d'
  on-tertiary-fixed: '#321200'
  on-tertiary-fixed-variant: '#763300'
  background: '#faf8ff'
  on-background: '#1a1b21'
  surface-variant: '#e2e2e9'
  brand-black: '#000000'
  status-success: '#4CAF50'
  surface-gray: '#F5F7F9'
  border-light: '#E0E4E8'
typography:
  display-lg:
    fontFamily: Arimo
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Arimo
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  headline-sm:
    fontFamily: Arimo
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Arimo
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Arimo
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Arimo
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  price-lg:
    fontFamily: Arimo
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 24px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  margin-mobile: 16px
  gutter-mobile: 12px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
  safe-area-bottom: 34px
---

## Brand & Style

The brand personality is efficient, reliable, and product-focused, designed specifically for a high-utility native mobile shopping experience. It targets users who value speed and clarity over lifestyle marketing.

The design system follows a **Minimalist / Corporate Modern** hybrid style. It prioritizes high legibility and functional density, heavily utilizing white space to frame products. Visual clutter is eliminated by using thin line-art icons and a strict structural grid inspired by high-end retail applications. The aesthetic is clean and institutional, ensuring the interface feels like a professional tool for commerce.

## Colors

The palette is derived directly from the brand identity, emphasizing trust and precision. 

- **Primary:** A deep navy blue used for primary actions, active navigation states, and key branding elements.
- **Secondary:** A bright sky blue used for secondary buttons, selection indicators, and accented informational badges.
- **Neutral:** Pure white (`#FFFFFF`) serves as the foundation for the background to maintain the minimalist "Tchibo-style" layout. Low-saturation grays are reserved for borders and subtle surface backgrounds for product cards or list items.
- **Contrast:** Black is used exclusively for typography and essential logo elements to ensure maximum readability.

## Typography

The system utilizes **Arimo** as a highly accessible alternative to Myriad Pro, ensuring a neutral, humanist sans-serif feel that thrives in mobile environments.

The typographic hierarchy is utilitarian. Headlines use bold weights to create clear section breaks in a content-heavy product catalog. Body text is optimized for quick scanning of technical specifications. Price points are treated as a distinct typographic role, utilizing the primary brand color and bold weights to ensure they are the most prominent information on product cards and detail pages.

## Layout & Spacing

The design system employs a **Fluid Grid** model optimized for narrow viewports. 

- **Grid:** A 4-column grid for mobile with 16px side margins. 
- **Product Display:** Use a 2-column "masonry-lite" or rigid grid for product listings to maximize the number of items visible above the fold. 
- **Vertical Rhythm:** A base 4px/8px spacing system is used to maintain tight relationships between labels and values while providing ample breathing room between distinct content blocks (e.g., product image vs. product title).
- **Sticky Zones:** The "Add to Cart" button and "Checkout" summaries are pinned to the viewport bottom with a background blur or solid white fill to ensure they float over scrolling content without causing visual tension.

## Elevation & Depth

To maintain a clean, native app feel, the system avoids heavy drop shadows in favor of **Tonal Layers and Low-Contrast Outlines**.

- **Surfaces:** Product cards use a thin `1px` border in `#E0E4E8` rather than shadows to define their bounds.
- **Top/Bottom Bars:** These utilize a subtle `0.5px` hairline border or a very soft, diffused shadow (0px 2px 10px, 5% opacity) to distinguish the navigation from the scrollable content.
- **Modals:** Only high-priority overlays (like quantity selectors) use a soft ambient shadow to provide depth and focus.

## Shapes

The shape language is **Soft** and professional. 

Buttons and input fields use a `4px` (0.25rem) corner radius. This provides a modern touch without the "playful" look of highly rounded or pill-shaped elements, which might detract from the technical/retail nature of the brand. Product images should maintain sharp or very slightly softened corners to emphasize the precision of the photography.

## Components

- **Buttons:** Primary buttons are solid `#214EA2` with white text. Sticky "Add to Cart" buttons must span the full width of the viewport (minus margins) for easy thumb access.
- **Icons:** Use thin `1.5pt` stroke "outline" icons. Active states in the Bottom Navigation are indicated by switching to a "filled" version of the icon in the primary color.
- **Top App Bar:** Centered Satur logo is mandatory. The background is solid white. Icons for "Profile" and "Notifications" are placed at the far left and right respectively.
- **Search Bar:** A prominent field with a light gray background (`#F5F7F9`), placed immediately below the Top App Bar to anchor the home and category views.
- **Product Cards:** Minimalist tiles containing a large image, a 2-line title limit, and a bold price. Icons for "Add to Wishlist" (heart) should be placed in the top-right corner of the image container.
- **Bottom Navigation:** A fixed bar with 4 specific slots: Home, Offer (Search/Categories), Wishlist, and Cart. No labels are required if icons are sufficiently distinct.