# ADMIN PROCUREMENT & TRACKING — Complete Project Instructions

This document is the full set of requirements given for this project, in the order they were requested, compiled so it can be reused or handed to Claude again in future if changes are needed. Paste the relevant sections back into a new conversation (with the current HTML file attached) to request modifications.

**Current live app:** https://claude.ai/artifact/XvZvFxVpedLVMt7HFiPXwY
**Current status:** All demo/dummy data has been removed. The app starts completely empty — the first person to use "New Registration" automatically becomes the Admin Manager.

---

## PART 1 — Original build request (verbatim structure, condensed)

**Role:** Senior full-stack web application architect, UI/UX designer, and JavaScript developer.

**Deliverable:** A complete, professional, responsive web application named **ADMIN PROCUREMENT & TRACKING**, usable by non-technical office/admin users, built exactly as specified with no omissions and no unnecessary extra features/menus/reports.

### 1. Objective
One system for the Admin Manager to control all admin-related procurement, purchase requests, recurring admin costs, ticket bookings/requests, approvals, assignments, execution, tracking, closure, and reporting. Must provide: centralized ticket/request management, master data management, role-based access, approval workflow, Admin Executive assignment/execution, recurring-ticket generation, live tracking, closed/completed history, vendor/category/periodic reports, import/export, cloud database storage initially with architecture prepared for migration to a private server later.

### 2. Technology
- HTML5, CSS3, Vanilla JavaScript (ES6+), no heavy framework unless necessary.
- Professional icon library (Font Awesome).
- Free-tier cloud database suitable for relational data with master tables, workflows, filtering, role-based access — **Supabase preferred**.
- Database layer isolated in a clearly marked service section so it can be replaced with a private Linux-server API/database later without redesigning the UI.
- Never expose a service-role/private database key client-side; use environment/configuration placeholders for public config.
- If cloud credentials are unavailable, include a clearly separated demo/local-storage fallback.
- No confidential business files sent to third-party AI services.
- Excel/CSV import processed safely and validated before database insertion.

### 3. Design / UI / UX
- Professional corporate administration/procurement theme.
- Primary color **#2596be**; font colors black and grey only; subtle shades/tints of the primary color for UI states; professional icons throughout; clean typography; modern cards/grids/panels/tables/modals/badges/buttons; minimal animation; no decorative clutter.
- Subtle, understated corporate background image with overlay that never reduces table readability.
- Fully responsive: desktop/laptop/tablet/mobile, no fixed width, tables horizontally scrollable or intelligently adapted on small screens.
- Global elements: app title, current date, running-month calendar, analog clock, user/profile info, logout, tooltips on unfamiliar icons, confirmation dialogs for destructive actions, toast notifications for save/update/delete/import/export.
- No unnecessary dashboards, KPIs, charts, or widgets beyond what's specified.

### 4. Login
- Username + 4-digit numeric PIN (numeric only, exactly 4 digits).
- Options: Login, Forgot Username/PIN, New Registration.
- Forgot Username/PIN: ask for registered email, validate format; if invalid/unregistered show "Share the Registered Email Address to enable"; never reveal sensitive account info.
- New Registration: email, username, 4-digit PIN; validate duplicate username/email and PIN format.
- After login: redirect to Home, load menus per role.

### 5. Roles / Access
Roles: **Requestor/Employee, Admin Executive, Admin Manager, Approver.**
- Admin Manager: Master, Admin Manager, Admin Executive, Reports, Settings.
- Employee/Requestor: Ticket Request.
- Admin Executive: Admin Executive.
- Approver: Approval.
- Reports: Admin Manager and Approver.
Unauthorized menus should be hidden (or shown locked/disabled if needed for nav consistency, never accessible). Authorization must be enforced at the data/API level too, not just hidden in UI.

### 6. Home Page
Left sidebar: **Master +** (Employee, Vendor, Category, Priority, Status, Currency, Recurring Costs), **Ticket Request**, **Admin Manager**, **Admin Executive**, **Approval**, **Reports +** (Tickets in Progress, Closed Tickets, Vendor Wise Reports, Category Wise Reports, Periodic Report), **Settings**. Only authorized menus shown. Right content area loads modules without full-page reload, keeps nav, shows title/breadcrumbs.

### 7. Master Tables
Every master: grid view, add/edit/delete, search, filter, sort, pagination, import/bulk upload, sample template download, export, validation, delete confirmation. **Admin Manager only.**

- **Employee**: Emp ID, Name, Designation, Branch, Email, Mobile No, User Type (Requestor/Admin Executive/Admin Manager/Approver).
- **Vendor**: Vendor ID, Name, Address, City, Email, Mobile No, Category, GST No.
- **Category**: ID, Category.
- **Priority**: ID, Priority. Defaults: Critical=C, High=H, Medium=M, Low=L. Deadlines: 2h / 4h / 24h / 48h respectively.
- **Status**: ID, Status. Reference values: Draft, New, Pending Approval, Approved, Assigned, In-Progress, Completed, Closed, Rejected.
- **Currency**: ID, Currency. Defaults: INR, USD, EUR, GBP, AED.
- **Recurring Costs**: ID, Cost Name, Location, Amount, Due Date, Vendor Name, End Date. Auto-generates tickets when due.

### 8. Master Import/Export
Import: accept CSV/Excel, preview before import, validate required fields, detect duplicates, row-level errors, don't insert invalid rows, show summary (total/successful/failed/duplicate). Export: currently-filtered dataset, CSV always, XLSX via client-side library.

### 9. Ticket Request (Requestor)
Grid: Request No, Requested By, Request Date, Request Time, Category, Details, Priority, Status. Functions: add/edit/search/filter/sort/import/template/export. Add-request fields: Requested By, Category, Details, Vendor, Currency, Cost, Priority, Approval Required (Yes/No). Validation: required fields, Details ≤250 chars, Cost numeric 2dp, Priority/Category/Vendor/Currency from their masters. On save: sequential Request Number, default status Draft, system date/time, created-by, audit info. Recent tickets on top. Status changes by Manager/Executive must reflect back here.

### 10. Admin Manager
Central ticket control dashboard. Shows tickets from Ticket Request (Draft) plus can create manual tickets. Can view/validate/edit/create/assign approver/send for approval/assign Admin Executive/change status/comment/export/import.

Grid: Ticket No, Request No, Requested By, Request Date, Request Time, Category, Details, Vendor, Currency, Cost, Approval Required, Approver, Assigned To, Priority, Status, Created Date/Time, Last Updated Date/Time. Sort by priority (Critical>High>Medium>Low) then newest first.

Manual ticket fields: Requested By (dropdown), Category (dropdown), Details (≤250), Vendor (dropdown), Currency (dropdown), Cost (numeric 2dp), Approval? (Yes/No), Approver (Employee dropdown filtered to Approvers, enabled only if Approval=Yes), Priority (dropdown). Auto ticket number, default status New, system date/time, creator saved.

Draft validation: review/validate; if no approval needed, allow assignment; if approval needed, select approver, show SEND button; sending sets state to Pending; visible to that approver.

Approval control: if approval required and not yet granted, Admin Executive assignment disabled; once Approved, enabled; if Rejected, no execution assignment allowed.

Assignment: Manager assigns approved tickets to an Admin Executive; status becomes Assigned; appears in that Executive's grid.

Status sync: any status change by Manager or Executive reflects in the Ticket Request record.

Closed tickets disappear from active grid, kept in Closed history.

Recurring tickets: check Recurring Master; when due date reached (and not past End Date), auto-create a ticket with status New; prevent duplicate creation for the same recurring item/occurrence; use the recurring item's Cost Name/Location/Amount/Vendor; record it as system-generated.

### 11. Admin Executive
Shows only tickets assigned to them. Grid: Ticket No, Received Date, Received Time, Category, Details, Vendor, Currency, Cost, Comments, Priority, Status. Sort by priority. Allowed status updates: In-Progress, Completed. Can open ticket, change status, update comments. Cannot approve/reject/reassign/edit masters/touch unrelated tickets. Completed tickets removed from active grid, retained in Completed history.

### 12. Approver
Only Approver users. Shows tickets sent to them by the Manager. Grid: Ticket No, Requested By, Request Date, Request Time, Category, Details, Vendor, Currency, Cost, Priority, Action Status (initially Pending). Sort by priority. Actions: Approve, Reject, Comments. Once decided, ticket leaves active grid, kept in history, result reflected back into the workflow.

### 13. Ticket Status Workflow
Controlled lifecycle, no arbitrary status jumps:
- Requestor: Draft
- Admin Manager: Draft → New / Pending Approval / Approved / Assigned / Rejected
- Approver: Pending → Approved / Rejected
- Admin Executive: Assigned → In-Progress → Completed
- Admin Manager: Completed → Closed

Enforce in JS and (where possible) at the DB layer. Maintain status history/audit trail: Ticket, Previous Status, New Status, Changed By, Changed Date, Changed Time, Comments.

### 14. Closed / Completed History
Closed Tickets = final status Closed. Completed Tickets = completed by Executive or completed approval actions. Never permanently delete completed/closed tickets just because they leave the active grid.

### 15. Reports
Only these, nothing extra:
1. Vendor Wise Ledger (vendor + date range filters, total cost)
2. Category Wise Ledger (category + date range filters, total cost)
3. Weekly Report (ticket activity/status summary)
4. Monthly Report (ticket activity/status summary)
5. Closed Tickets Report (with filters)
6. Tickets in Live/Active Report

Each with search/filter, date filters, export, clear/reset. No unrelated financial/HR/analytics reports.

### 16. Settings
Minimal, Admin Manager only: user/session management, application configuration, database connection/configuration placeholder, basic workflow configuration if necessary. No unnecessary extra settings screens.

### 17. Data Model
Relational tables: users, employees, vendors, categories, priorities, statuses, currencies, recurring_master, tickets, ticket_comments, ticket_assignments, ticket_approvals, ticket_status_history, audit_log. Ticket table fields: Ticket ID, Request No, Requested By, Request Date, Request Time, Category, Details, Vendor, Currency, Cost, Priority, Approval Required, Approver, Approval Status, Assigned Executive, Status, Source (Manual/Request/Recurring), Created By, Created At, Updated By, Updated At, Closed At. Unique identifiers, no duplicate ticket/request numbers.

### 18. Security / Data Safety
Input validation, role-based UI + DB access, session handling, no private keys or hard-coded passwords/admin credentials in HTML, safe queries, basic audit logging, confirmation before destructive actions, error handling. DB connection configurable and isolated for later migration to a private Linux server.

### 19. Import/Export Templates
Sample templates (correct column headings) for: Employee, Vendor, Category, Priority, Status, Currency, Recurring Master, Ticket Request.

### 20. UX Details
Professional data tables, sticky headers where useful, compact filters, modal forms, confirmation dialogs, toast notifications, loading indicators, empty/error states, consistent Add/Edit/Save/Cancel/Delete buttons, accessible icon labels, keyboard-friendly controls. Don't overload screens.

### 21. Calendar & Clock
Home page: current running-month calendar highlighting today; analog clock updating in real time; uses browser local date/time.

### 22. Audit Trail
Record: login, registration, create, edit, delete, import, export, ticket assignment, approval submission, approval/rejection, status changes, closure. Show only where useful; no unnecessary standalone audit report screen.

### 23. Responsive Behavior
Desktop: sidebar + content. Tablet: collapsible sidebar. Mobile: sidebar becomes a drawer, tables horizontally scrollable, modals fit screen, buttons usable, nothing cut off.

### 24. Demo/Test Data (superseded — see Part 3)
Originally requested a small amount of clearly-marked realistic sample data. **This has since been removed at the user's request (Part 3) — the app now ships with zero business records.**

### 25. Error Handling
Clear messages for: invalid login/PIN, missing required fields, invalid email, invalid numeric cost, duplicate master/request/ticket, unauthorized action, approval required before assignment, DB connection failure, import validation errors, export failure. Never show technical stack traces.

### 26. Application Structure
Single HTML file acceptable: CSS in `<style>`, JS in `<script>`, organized into clearly commented logical sections (Authentication, Navigation, Masters, Ticket Requests, Admin Manager, Admin Executive, Approver, Reports, Database Service, Import/Export, Validation, Utilities).

### 27. Testing Checklist
Login (valid/invalid/PIN/registration/forgot), access per role, master CRUD/import/export/validation, ticket request lifecycle, Admin Manager workflows (validation, manual ticket, priority sort, approval assignment/restriction, executive assignment, status update, closed history), Approver actions, Admin Executive actions, recurring generation (due-date, no duplicates, end-date), reports (all 6 + filters + export), responsive (desktop/tablet/mobile).

### 28. Final Deliverable
Downloadable HTML file (or project files), database setup instructions, required schema, free cloud DB configuration steps, migration path to a private Linux server, demo/test login credentials if included, short user guide, concise implemented-modules list. Build exactly what's requested — no unnecessary features, professional/corporate UI, simple workflow, actually functional (not a mock-up).

**Reference workbook note:** An Excel workbook "Process Flow.xlsx" was originally offered as a functional reference for master data/fields/menus/workflows/status values, with this prompt taking priority wherever the two differ. The workbook was never actually uploaded/used in the build.

---

## PART 2 — Follow-up change requests (applied after the first build)

1. Admin Manager grid: when a ticket requires approval, show the list of approvers to select from.
2. Record-wise Edit option so the Admin Manager can change ticket status and Admin Executive assignment directly.
3. Include Request Time in the Admin Manager grid (not just date).
4. Fix: at 100% browser zoom the grid should never need a horizontal scroll to see all columns.
5. Don't show the full ticket description in the grid — show a "full view" (eye) icon; clicking it opens the details in a pop-up.
6. Show priority as a single letter badge: **C** (Critical), **H** (High), **M** (Medium), **L** (Low) instead of the full word.
7. Priority Master: add a deadline-to-complete field per level — Critical 2 hours, High 4 hours, Medium 24 hours, Low 48 hours.
8. Any ticket that has crossed its deadline must be highlighted in the grid with a blinking effect.
9. Every record needs Edit and Delete options.
10. **Admin Manager → Create New Ticket** popup must not close when clicking outside it — only via "Create Ticket" or "Cancel".
11. When creating a ticket, if "Approval Required" = Yes, show the list of approvers so the request can be routed for approval.
12. Show the list of Admin Executives in the grid's "Assigned To" field so the Manager can assign directly from the grid.
13. Approver name displayed as **first name only** everywhere in grids.
14. Show a Status dropdown directly in the grid so the Manager (or Executive, on their own screen) can change status inline based on progress.
15. Rename grid headers to: **Ticket #, Req ID, Requestor, Date, Time, Category, Vendor, Priority, Cost, Approved?, Approver, Handler, Status, Details** (plus Actions).
16. Approval Status shown as a single letter: **A** (Approved), **R** (Rejected), **P** (Pending).
17. Manually created tickets (by the Admin Manager) default to status **New** (not Draft).
18. While a ticket is awaiting Approver action (Pending), the "Assign To" / Handler field must be disabled for that record.
19. The Admin Manager can change the Approver on a ticket at any stage, regardless of status.
20. Only tickets with status **Draft** or **New** can be deleted.
21. A ticket **rejected by the Admin Manager** must be removed from the active Admin Manager grid (kept in report history instead).
22. Save these instructions to memory; provide a downloadable memory file plus the HTML file. *(Superseded by the memory-file mechanics of the platform — this document serves that purpose now.)*

---

## PART 3 — Later feature additions

23. **Settings → User Management — per-user menu access.** The Admin Manager must be able to assign/change, for each individual user (Requestors, Admin Executives, Approvers), exactly which menus they can access — not just a fixed role-based default. Implemented as: each of those three roles has a candidate menu list (Requestor: Ticket Request + optional Reports; Admin Executive: Admin Executive + optional Reports; Approver: Approval + optional Reports), editable per-user via an "Edit menu access" action in Settings → User/Session Management. Admin Manager accounts always retain full access and aren't editable this way.
24. **Home screen — clickable stats.** Clicking the "Active tickets" or "Overdue" counts on the Home screen navigates straight to the logged-in user's working dashboard (Admin Manager / Admin Executive / Approval / Ticket Request depending on role) and shows those tickets; clicking Overdue pre-applies a "Deadline: Overdue only" filter.
25. **Remove all dummy/demo records.** The app must ship with zero seeded business data (no sample employees, vendors, categories, tickets, or demo logins) so real testing data isn't mixed in with placeholders. Only the essential system defaults remain: the four Priority levels, the nine core Statuses, and the five Currencies (these are workflow scaffolding, not "dummy records"). The very first person to use "New Registration" on a blank installation automatically becomes the Admin Manager, so the app is fully usable from an empty state without any hard-coded admin account. This same bootstrap behavior was added to the Supabase cloud schema's `app_register` function for consistency.
26. **Host on Claude's server, not locally.** The HTML file is published as a Claude Artifact (a hosted claude.ai link) rather than only being handed over as a local download, so it doesn't need to be run from anyone's own machine. Making that link **public** (so anyone worldwide can open it without a Claude account) is a sharing-permission toggle on the artifact's own page that only the owning user can set — it cannot be flipped by Claude through any tool call.

---

## Known limitation to carry forward

In **local demo mode** (no Supabase configured), each visitor's browser keeps its own private copy of the data in `localStorage` — nothing is shared between different people opening the same public link. For everyone to see and edit the *same* live tickets/masters, Supabase must be configured (see `supabase_schema.sql` and the README's setup steps) before wide distribution.

---

## Files that make up this delivery
- `admin_procurement_tracking.html` — the complete application (single self-contained file).
- `supabase_schema.sql` — full Postgres schema, Row Level Security policies, and RPC functions for the free cloud database tier, including the bootstrap-first-Admin-Manager registration logic.
- `README.md` — setup instructions, demo/user guide, migration notes to a private Linux server.
- This file — the full instruction history, for reuse if further changes are needed.
