# ADMIN PROCUREMENT & TRACKING — Setup & User Guide

## 1. Files delivered
| File | Purpose |
|---|---|
| `admin_procurement_tracking.html` | The complete application. Open it in any modern browser, or host it on any web server / intranet. |
| `supabase_schema.sql` | Run once in Supabase to create the cloud database (tables, security rules, login functions). |
| `README.md` | This guide. |

## 2. Running it today (Demo mode — no setup needed)
Just open `admin_procurement_tracking.html` in a browser (or the published link, if you were given one). It detects that no cloud database is configured and runs on **local demo mode**, storing data in the browser's `localStorage`. This is a **completely clean install** — no sample employees, vendors, tickets, or logins are pre-loaded.

**First-time setup:** click **New Registration** and register with any email/username/PIN. The very first person to register on a blank installation is automatically made the **Admin Manager**. From there, log in and start adding real Employees, Vendors, Categories, etc. through the Master screens (or Import them). Every registration after the first one requires the email to already exist in the Employee Master, added by the Admin Manager.

Note: in local demo mode, each browser/device keeps its own private copy of the data — it is not shared between different people opening the same link. To get one shared, live dataset for everyone, configure Supabase (next section).

## 3. Moving to the free cloud database (Supabase)
1. Create a free project at supabase.com.
2. Open **SQL Editor** in your Supabase project, paste the entire contents of `supabase_schema.sql`, and run it. This creates all tables, the default Priority/Status/Currency masters, role-based Row Level Security, and the login/registration functions (including the same "first person to register becomes Admin Manager" bootstrap used in demo mode).
3. In Supabase, go to **Settings → API** and copy the **Project URL** and the **anon public** key (never the `service_role` key).
4. In the app (still in local demo mode at this point), register once and log in as the local Admin Manager, then go to **Settings → Database Connection** → paste the URL and anon key → **Save & Reload**.
5. After the reload the app is now talking to your empty Supabase database, so log in fails until you **register again** — this second registration bootstraps the real, cloud-based Admin Manager account.
6. Add your real Employees, Vendors, Categories, etc. through the Master screens, or use **Import**.

The app never sends the private/service-role key anywhere — only the public anon key, which is safe to embed in browser code because all real permission checks happen in PostgreSQL Row Level Security.

## 4. Moving later to your own Linux server
The database layer is isolated in one clearly commented section of the HTML file (`DATABASE SERVICE`), behind a single object called `DB` with methods like `list`, `insert`, `update`, `remove`, `login`. To move off Supabase:
1. Run PostgreSQL + PostgREST (or any REST layer that speaks the same call shape) on your Linux server, using the same `supabase_schema.sql` (Supabase is just managed Postgres + PostgREST).
2. In **Settings → Database Connection**, point the URL at your server and set the API prefix accordingly.
3. No UI code changes are required — every screen calls the same `DB.*` methods regardless of where they point.

## 5. Database tables (schema summary)
`employees`, `vendors`, `categories`, `priorities`, `statuses`, `currencies`, `recurring_master`, `users`, `tickets`, `ticket_comments`, `ticket_assignments`, `ticket_approvals`, `ticket_status_history`, `audit_log`, `app_settings`. Full column definitions, constraints, indexes and Row Level Security policies are in `supabase_schema.sql`.

## 6. User guide (quick reference)

### Logging in
Enter your **Username** and **4-digit PIN**. On a brand-new installation with no accounts yet, the first person to use **New Registration** (with any email/username/PIN) automatically becomes the Admin Manager. After that, new employees must already be listed in the Employee Master (added by the Admin Manager) before they can self-register. If you forget your PIN, use **Forgot Username / PIN** — the Admin Manager will reset it from **Settings → User / Session Management**.

### Requestor / Employee
Go to **Ticket Request → New Request**, fill in Category, Vendor, Details (250 characters max), Cost, Priority, and whether approval is required. The request is saved as **Draft** with an automatic Request Number. You can edit or delete it only while it is still Draft.

### Admin Manager
The **Admin Manager** screen is the control center for every ticket:
- **Create Ticket** for purchases that didn't come through a request.
- If approval is required, pick an **Approver** and click the send icon to move it to Pending Approval.
- Once approved (or if no approval was needed), pick an **Admin Executive** in the **Handler** column to assign the work.
- Change **Status** directly from the dropdown as work progresses; use the eye icon to see full details, history and comments.
- Edit or delete a ticket only while it is Draft/New. Closed and Rejected tickets leave this working grid automatically (they remain visible in Reports).
- Rows that have passed their priority's deadline blink so overdue items are easy to spot.

### Admin Executive
See only tickets assigned to you. Move them to **In-Progress** and then **Completed**; add comments with the comment icon. Completed tickets leave your active list automatically.

### Approver
See only tickets sent to you. **Approve** or **Reject** (a reason is required for rejection). Decided tickets leave your active queue automatically and the result flows back to the Admin Manager.

### Reports (Admin Manager & Approver)
Vendor Wise, Category Wise, Weekly/Monthly (Periodic Report), Closed Tickets, and Tickets in Progress — each with date/status filters, totals, and CSV/Excel export.

### Masters & Settings (Admin Manager only)
Maintain Employees, Vendors, Categories, Priorities (with deadline hours), Statuses, Currencies and Recurring Costs — each with Add/Edit/Delete, Import (with a downloadable sample template and row-level validation), and Export. Recurring Costs automatically generate a new ticket once their due date arrives, without duplicating an already-generated occurrence. Settings also holds the database connection, basic workflow defaults, demo-data cleanup, per-user menu access, and PIN resets/disable.

### Per-user menu access (Settings → User / Session Management)
Beyond the standard role-based menus, the Admin Manager can fine-tune exactly which menus each individual Requestor, Admin Executive or Approver sees — for example granting one specific Approver access to Reports while leaving another without it, or temporarily hiding an Admin Executive's own working screen without disabling their login. Click **Edit menu access** on a user's row, tick the menus they should see, and **Save** — it takes effect the next time that user's screen is refreshed/logged in. Admin Manager accounts always keep full access and aren't editable this way.

### Home screen quick links
The **Active tickets** and **Overdue** counts on the Home screen are clickable — clicking either jumps straight to your working dashboard (Admin Manager / Admin Executive / Approval / Ticket Request, depending on your role) with the Overdue filter pre-applied when relevant.

## 7. Modules implemented
Login (with registration & forgot PIN) · Role-based navigation · Employee, Vendor, Category, Priority, Status, Currency, Recurring Cost masters (CRUD, import, export, templates) · Ticket Request · Admin Manager (manual tickets, approval routing, assignment, status control) · Admin Executive · Approver · Reports (Vendor Wise, Category Wise, Weekly/Monthly, Closed, In-Progress) · Settings (database connection, workflow defaults, user/session management, demo data) · Audit trail · Home (calendar + live analog clock).
