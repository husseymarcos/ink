# Design System Specification: Editorial Vellum

## 1. Overview & Creative North Star
**The Creative North Star: "The Digital Vellum"**
This design system moves away from the rigid, boxed-in constraints of traditional SaaS platforms. Instead, it treats the screen as a tactile, premium workspace—a "Digital Vellum." By combining the authoritative weight of editorial typography with a sophisticated layering of surfaces, we create an environment that feels both expansive and focused.

We break the "template" look by favoring **intentional asymmetry** and **tonal depth** over borders. High-contrast typography scales (Manrope paired with Inter) drive the hierarchy, while the vibrant primary blue (#1D4ED8) and magenta accent (#C026D3) are used sparingly as "ink" on the page—moments of high-energy intent amidst a calm, layered background.

---

## 2. Colors & Surface Philosophy
The palette is rooted in a cool, sophisticated base that allows the vibrant brand colors to pop without overwhelming the user’s cognitive load.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders for sectioning or containment. Boundaries must be defined solely through background color shifts or subtle tonal transitions. For example, a sidebar should be defined by `surface-container-low` sitting against a `surface` background.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—stacked sheets of vellum.
*   **Base Layer:** `surface` (#faf8ff)
*   **Secondary Content:** `surface-container-low` (#f3f2fe)
*   **Elevated Components:** `surface-container-highest` (#e2e1ed)
*   **Floating Elements:** `surface-container-lowest` (#ffffff)

### The "Glass & Gradient" Rule
To elevate the experience beyond "flat design," use **Glassmorphism** for floating elements (drawers, popovers). Utilize `surface` colors at 80% opacity with a `20px` backdrop-blur. 
*   **Signature Textures:** For primary CTAs or Hero backgrounds, use a subtle linear gradient (45deg) transitioning from `primary` (#0037b0) to `primary_container` (#1d4ed8). This adds a "soul" to the interface that flat fills lack.

---

## 3. Typography: The Editorial Voice
We use a dual-font strategy to balance character with utility.

*   **Display & Headlines (Manrope):** These are your "Editorial" voices. Use `display-lg` (3.5rem) and `headline-lg` (2rem) with tight letter-spacing (-0.02em) to create an authoritative, premium feel. 
*   **Body & Labels (Inter):** These are your "Functional" voices. Inter provides exceptional legibility at small scales.
*   **Hierarchy Note:** Use `tertiary` (#790088) for `label-md` in specialized contexts (like tags or overlines) to provide a sophisticated magenta counterpoint to the blue-dominant layout.

---

## 4. Elevation & Depth
Depth in this system is a result of **Tonal Layering**, not structural decoration.

*   **The Layering Principle:** Place a `surface-container-lowest` card on a `surface-container-low` section. The change in hex value creates a soft, natural lift.
*   **Ambient Shadows:** For floating modals, use a custom "Ambient Blue" shadow: `0 20px 40px rgba(0, 55, 176, 0.06)`. This mimics natural light passing through a blue-tinted environment rather than a harsh grey shadow.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility, use the `outline_variant` (#c4c5d7) at **15% opacity**. Never use 100% opaque borders.

---

## 5. Components

### Buttons
*   **Implementation:** Use `<.button>` in `InkWeb.CoreComponents` (Tailwind classes in the component; no button rules in `app.css`).
*   **Primary:** Fill with the Signature Gradient (`primary` to `primary_container`). Pill shape via `rounded-full` utilities on the component. Text: `label-md` uppercase with 0.05em tracking.
*   **Secondary:** Ghost style. No background, `primary` text. Use a 10% opacity `primary` fill on hover.
*   **Tertiary (Accent):** Use `tertiary_container` (#a000b3) with `on_tertiary` (#ffffff) text for high-importance "creation" actions.

### Cards & Lists
*   **Anti-Pattern:** No divider lines between list items.
*   **Pattern:** Use `spacing-2` (normal spacing) of vertical white space to separate items. For high-density lists, alternate background tones between `surface` and `surface-container-low`.

### Input Fields
*   **Styling:** Use `surface_container_lowest` (#ffffff) for the input fill. 
*   **Active State:** Instead of a thick border, use a 2px bottom-accent in `primary` (#0037b0) and a soft `surface_tint` glow.

### Signature Component: The "Vellum Slide"
A side-panel component using Glassmorphism (80% `surface_container_low` with blur). This allows the main workspace content to remain visible as a blurred texture behind the active task.

---

## 6. Do's and Don'ts

### Do
*   **DO** use the `spacing-12` and `spacing-16` tokens to create "Hero" breathing room at the top of pages.
*   **DO** use `tertiary` (#790088) magenta for micro-interactions (like a successful checkmark or a notification dot).
*   **DO** lean into asymmetry. For example, left-align headlines while right-aligning action buttons with significant white space between them.

### Don't
*   **DON'T** use `outline` (#747686) for anything other than text-entry borders at low opacity. It is too heavy for decorative use.
*   **DON'T** use "Drop Shadows" on cards that are sitting on the base surface; use tonal shifts instead.
*   **DON'T** use the standard Magenta `tertiary` for large background areas; it is an accent "ink," not a structural "paper."