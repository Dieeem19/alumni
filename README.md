# BCP System UI Template

Shared na base UI para sa lahat ng subsystem (Library, Clinic, Cashier, atbp.)
para pare-pareho ang itsura kahit magkaiba ang backend/functionality.

## Laman ng folder

```
UI-Template/
├── login.html          ← sign-in page
├── dashboard.html       ← dashboard shell (topbar + sidebar + content)
├── assets/
│   ├── css/theme.css    ← LAHAT ng colors, fonts, at reusable components dito
│   └── js/main.js       ← sidebar toggle, clock, password show/hide
```

## Paano gamitin (para sa bawat subsystem)

1. I-copy ang buong `library-template` folder bilang starting point ng subsystem mo.
2. **Huwag babaguhin** ang `theme.css` variables (`:root { ... }`) — dito nakabase
   ang lahat ng kulay/font, para automatic na pare-pareho lahat ng group.
3. Palitan na lang ang:
   - `BCP SUBSYSTEM NAME` sa topbar → pangalan ng subsystem mo (hal. "BCP Clinic")
   - Mga link sa `<aside class="sidebar">` → mga module/pages ng subsystem mo
   - Laman ng `<main class="main-content">` → content mo (tables, forms, cards)
4. Gamitin ang mga existing na CSS classes (`.card`, `.data-table`, `.btn-primary`,
   `.badge-success`, `.stat-card`, etc.) sa halip na gumawa ng bagong style, para
   consistent pa rin kahit magkaiba ang laman.
5. Kung may bagong komponent kang kailangan na wala pa sa `theme.css`, i-add mo
   siya doon (hindi sa sarili mong file) para magamit din ng iba, at i-announce
   sa group chat na may dinagdag ka.

## Mga component na available na sa theme.css

- Buttons: `.btn .btn-primary`, `.btn .btn-outline`, `.btn .btn-danger`
- Forms: `.form-group`, `.form-label`, `.form-control`
- Cards: `.card`, `.card-header`
- Table: `.data-table`
- Stat boxes: `.stat-grid` + `.stat-card`
- Status labels: `.badge-success`, `.badge-warning`, `.badge-danger`, `.badge-info`
- Banner: `.banner`
- Empty states: `.empty-state`

Buksan mo lang ang `login.html` at `dashboard.html` sa browser (double-click,
walang kailangang server) para makita agad ang preview.
