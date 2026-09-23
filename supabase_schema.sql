-- =====================================================================
-- ADMIN PROCUREMENT & TRACKING — Supabase / PostgreSQL schema
-- =====================================================================
-- Run this whole file once in Supabase: Project > SQL Editor > New query > Run.
-- It creates all tables, role-based Row Level Security (RLS) policies, and the
-- RPC functions the app calls for login/registration (so PINs are hashed on
-- the server and the anon key never needs direct table INSERT on `users`).
--
-- After running this file, put your Project URL and "anon public" key into
-- the app's Settings > Database screen. NEVER put the "service_role" key
-- into the app or into this app's Settings screen.
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- MASTER TABLES
-- ---------------------------------------------------------------------
create table employees (
  id           bigint generated always as identity primary key,
  emp_code     text not null unique,
  name         text not null,
  designation  text not null,
  branch       text,
  email        text not null unique,
  mobile       text not null,
  user_type    text not null check (user_type in ('Requestor','Admin Executive','Admin Manager','Approver')),
  is_demo      boolean default false,
  created_at   timestamptz default now()
);

create table vendors (
  id           bigint generated always as identity primary key,
  vendor_code  text not null unique,
  name         text not null,
  address      text,
  city         text not null,
  email        text not null,
  mobile       text not null,
  category_id  bigint,
  gst_no       text,
  is_demo      boolean default false,
  created_at   timestamptz default now()
);

create table categories (
  id         bigint generated always as identity primary key,
  name       text not null unique,
  is_demo    boolean default false,
  created_at timestamptz default now()
);

create table priorities (
  id              bigint generated always as identity primary key,
  name            text not null unique,
  code            text not null,
  deadline_hours  numeric not null check (deadline_hours > 0),
  created_at      timestamptz default now()
);

create table statuses (
  id         bigint generated always as identity primary key,
  name       text not null unique,
  created_at timestamptz default now()
);

create table currencies (
  id         bigint generated always as identity primary key,
  name       text not null unique,
  created_at timestamptz default now()
);

create table recurring_master (
  id          bigint generated always as identity primary key,
  cost_name   text not null,
  location    text,
  amount      numeric not null check (amount > 0),
  due_date    date not null,
  vendor_id   bigint references vendors(id),
  end_date    date,
  is_demo     boolean default false,
  created_at  timestamptz default now()
);

-- vendors.category_id references categories which is declared after vendors above;
-- fix the forward reference:
alter table vendors add constraint vendors_category_fk foreign key (category_id) references categories(id);

-- ---------------------------------------------------------------------
-- USERS  (login credentials; PIN is hashed, never stored in plain text)
-- ---------------------------------------------------------------------
create table users (
  id               bigint generated always as identity primary key,
  username         text not null unique,
  emp_id           bigint not null references employees(id) on delete cascade,
  salt             text not null,
  pin_hash         text not null,
  active           boolean default true,
  failed_attempts  int default 0,
  locked_until     timestamptz,
  last_login       timestamptz,
  reset_requested  boolean default false,
  session_token    text,
  session_expires  timestamptz,
  menu_access      jsonb, -- null = use role default; array of menu keys otherwise (e.g. '["approval","reports"]')
  is_demo          boolean default false,
  created_at       timestamptz default now()
);

-- ---------------------------------------------------------------------
-- TICKETS  (the core workflow table)
-- ---------------------------------------------------------------------
create table tickets (
  id                 bigint generated always as identity primary key,
  ticket_no          text not null unique,
  request_no         text unique,
  requested_by       bigint references employees(id),
  request_date       date not null,
  request_time       time not null,
  category_id        bigint references categories(id),
  details            text not null check (char_length(details) <= 250),
  vendor_id          bigint references vendors(id),
  currency_id        bigint references currencies(id),
  cost               numeric(14,2) not null check (cost >= 0),
  priority_id        bigint references priorities(id),
  approval_required  boolean default false,
  approver_id        bigint references employees(id),
  approval_status    text default 'NA' check (approval_status in ('NA','Not Sent','Pending','Approved','Rejected')),
  handler_id         bigint references employees(id),
  status             text not null default 'Draft',
  source             text not null check (source in ('Manual','Request','Recurring')),
  recurring_id       bigint references recurring_master(id),
  occurrence_date    date,
  created_by         bigint references users(id),
  created_at         timestamptz default now(),
  updated_by         bigint references users(id),
  updated_at         timestamptz default now(),
  closed_at          timestamptz,
  is_demo            boolean default false,
  unique (recurring_id, occurrence_date)
);
create index idx_tickets_status on tickets(status);
create index idx_tickets_handler on tickets(handler_id);
create index idx_tickets_approver on tickets(approver_id);
create index idx_tickets_requested_by on tickets(requested_by);

create table ticket_comments (
  id           bigint generated always as identity primary key,
  ticket_id    bigint not null references tickets(id) on delete cascade,
  user_id      bigint references users(id),
  author_name  text,
  comment      text not null check (char_length(comment) <= 500),
  created_at   timestamptz default now(),
  is_demo      boolean default false
);

create table ticket_assignments (
  id            bigint generated always as identity primary key,
  ticket_id     bigint not null references tickets(id) on delete cascade,
  executive_id  bigint references employees(id),
  assigned_by   bigint references users(id),
  assigned_at   timestamptz default now(),
  is_demo       boolean default false
);

create table ticket_approvals (
  id           bigint generated always as identity primary key,
  ticket_id    bigint not null references tickets(id) on delete cascade,
  approver_id  bigint references employees(id),
  sent_by      bigint references users(id),
  sent_at      timestamptz default now(),
  decision     text default 'Pending' check (decision in ('Pending','Approved','Rejected')),
  decided_at   timestamptz,
  comments     text,
  is_demo      boolean default false
);

create table ticket_status_history (
  id               bigint generated always as identity primary key,
  ticket_id        bigint not null references tickets(id) on delete cascade,
  prev_status      text,
  new_status       text not null,
  changed_by       bigint references users(id),
  changed_by_name  text,
  changed_at       timestamptz default now(),
  comments         text,
  is_demo          boolean default false
);

create table audit_log (
  id          bigint generated always as identity primary key,
  user_id     bigint references users(id),
  username    text,
  action      text not null,
  entity      text not null,
  entity_ref  text,
  details     text,
  created_at  timestamptz default now()
);

create table app_settings (
  id         bigint generated always as identity primary key,
  key        text not null unique,
  value      text,
  updated_at timestamptz default now()
);

-- default lookup data (same as the app's demo master seed, without the demo flag)
insert into priorities (name, code, deadline_hours) values
  ('Critical','C',2), ('High','H',4), ('Medium','M',24), ('Low','L',48);
insert into statuses (name) values
  ('Draft'),('New'),('Pending Approval'),('Approved'),('Assigned'),('In-Progress'),('Completed'),('Closed'),('Rejected');
insert into currencies (name) values ('INR'),('USD'),('EUR'),('GBP'),('AED');
insert into app_settings (key, value) values ('session_timeout','30'), ('rec_priority_id','3'), ('rec_currency_id','1');

-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================
-- The app authenticates with the public "anon" key for every request and
-- identifies the signed-in user via app_login()/app_me() below (a small
-- custom session system, since this app does not use Supabase Auth).
-- current_setting('request.jwt.claims') is not used; instead each RLS
-- policy calls app_current_user_id(), which trusts the `x-app-token`
-- request header set by the browser after login.

alter table employees enable row level security;
alter table vendors enable row level security;
alter table categories enable row level security;
alter table priorities enable row level security;
alter table statuses enable row level security;
alter table currencies enable row level security;
alter table recurring_master enable row level security;
alter table tickets enable row level security;
alter table ticket_comments enable row level security;
alter table ticket_assignments enable row level security;
alter table ticket_approvals enable row level security;
alter table ticket_status_history enable row level security;
alter table audit_log enable row level security;
alter table app_settings enable row level security;
alter table users enable row level security; -- no direct policies: users table is only reachable via the RPCs below

-- Helper: resolve the calling user from the x-app-token header set by the app.
create or replace function app_current_user_id() returns bigint
language sql stable security definer as $$
  select u.id from users u
  where u.session_token = current_setting('request.headers', true)::json ->> 'x-app-token'
    and u.session_expires > now()
  limit 1;
$$;
create or replace function app_current_role() returns text
language sql stable security definer as $$
  select e.user_type from users u join employees e on e.id = u.emp_id where u.id = app_current_user_id();
$$;
create or replace function app_current_emp_id() returns bigint
language sql stable security definer as $$
  select u.emp_id from users u where u.id = app_current_user_id();
$$;

-- Masters: everyone signed in can read; only Admin Manager can write.
create policy master_read on employees for select using (app_current_user_id() is not null);
create policy master_write on employees for all using (app_current_role() = 'Admin Manager') with check (app_current_role() = 'Admin Manager');
create policy v_read on vendors for select using (app_current_user_id() is not null);
create policy v_write on vendors for all using (app_current_role() = 'Admin Manager') with check (app_current_role() = 'Admin Manager');
create policy c_read on categories for select using (app_current_user_id() is not null);
create policy c_write on categories for all using (app_current_role() = 'Admin Manager') with check (app_current_role() = 'Admin Manager');
create policy p_read on priorities for select using (app_current_user_id() is not null);
create policy p_write on priorities for all using (app_current_role() = 'Admin Manager') with check (app_current_role() = 'Admin Manager');
create policy s_read on statuses for select using (app_current_user_id() is not null);
create policy s_write on statuses for all using (app_current_role() = 'Admin Manager') with check (app_current_role() = 'Admin Manager');
create policy cu_read on currencies for select using (app_current_user_id() is not null);
create policy cu_write on currencies for all using (app_current_role() = 'Admin Manager') with check (app_current_role() = 'Admin Manager');
create policy r_read on recurring_master for select using (app_current_user_id() is not null);
create policy r_write on recurring_master for all using (app_current_role() = 'Admin Manager') with check (app_current_role() = 'Admin Manager');
create policy set_read on app_settings for select using (app_current_user_id() is not null);
create policy set_write on app_settings for all using (app_current_role() = 'Admin Manager') with check (app_current_role() = 'Admin Manager');

-- Tickets: Admin Manager sees/edits all; Requestor sees/edits own; Executive sees/edits assigned; Approver sees assigned-for-approval.
create policy t_select on tickets for select using (
  app_current_role() = 'Admin Manager'
  or requested_by = app_current_emp_id()
  or handler_id = app_current_emp_id()
  or approver_id = app_current_emp_id()
);
create policy t_insert on tickets for insert with check (
  app_current_role() = 'Admin Manager' or (app_current_role() = 'Requestor' and requested_by = app_current_emp_id())
);
create policy t_update on tickets for update using (
  app_current_role() = 'Admin Manager'
  or (app_current_role() = 'Requestor' and requested_by = app_current_emp_id() and status = 'Draft')
  or (app_current_role() = 'Admin Executive' and handler_id = app_current_emp_id())
  or (app_current_role() = 'Approver' and approver_id = app_current_emp_id())
);
create policy t_delete on tickets for delete using (
  app_current_role() = 'Admin Manager' or (app_current_role() = 'Requestor' and requested_by = app_current_emp_id() and status = 'Draft')
);

-- Child tables follow the parent ticket's visibility.
create policy tc_all on ticket_comments for all using (
  exists (select 1 from tickets t where t.id = ticket_id and (
    app_current_role() = 'Admin Manager' or t.requested_by = app_current_emp_id() or t.handler_id = app_current_emp_id() or t.approver_id = app_current_emp_id()))
) with check (app_current_user_id() is not null);
create policy ta_all on ticket_assignments for all using (app_current_role() in ('Admin Manager','Admin Executive')) with check (app_current_role() = 'Admin Manager');
create policy tap_all on ticket_approvals for all using (
  app_current_role() = 'Admin Manager' or approver_id = app_current_emp_id()
) with check (app_current_role() in ('Admin Manager','Approver'));
create policy tsh_select on ticket_status_history for select using (
  exists (select 1 from tickets t where t.id = ticket_id and (
    app_current_role() = 'Admin Manager' or t.requested_by = app_current_emp_id() or t.handler_id = app_current_emp_id() or t.approver_id = app_current_emp_id()))
);
create policy tsh_insert on ticket_status_history for insert with check (app_current_user_id() is not null);

-- Audit log: Admin Manager can read; any signed-in user can write their own action.
create policy al_select on audit_log for select using (app_current_role() = 'Admin Manager');
create policy al_insert on audit_log for insert with check (app_current_user_id() is not null);

-- =====================================================================
-- RPC FUNCTIONS  (login / registration / session — called with the anon key)
-- =====================================================================
create or replace function app_register(p_email text, p_username text, p_pin text)
returns json language plpgsql security definer as $$
declare v_emp employees; v_exists int; v_user_count int;
begin
  if p_pin !~ '^[0-9]{4}$' then return json_build_object('ok', false, 'error', 'PIN must be exactly 4 digits.'); end if;
  select count(*) into v_exists from users where lower(username) = lower(p_username);
  if v_exists > 0 then return json_build_object('ok', false, 'error', 'Username already exists. Choose another username.'); end if;
  select * into v_emp from employees where lower(email) = lower(p_email);
  select count(*) into v_user_count from users;
  if v_user_count = 0 then
    -- first-ever registration on a clean install: bootstrap this person as the Admin Manager
    if v_emp.id is null then
      insert into employees (emp_code, name, designation, branch, email, mobile, user_type)
        values ('ADM001', p_username, 'Admin Manager', '', p_email, '', 'Admin Manager') returning * into v_emp;
    else
      update employees set user_type = 'Admin Manager' where id = v_emp.id returning * into v_emp;
    end if;
  else
    if v_emp.id is null then return json_build_object('ok', false, 'error', 'This email address is not in the Employee master. Please contact the Admin Manager.'); end if;
    if exists (select 1 from users where emp_id = v_emp.id) then
      return json_build_object('ok', false, 'error', 'This email address is already registered.');
    end if;
  end if;
  declare v_salt text := encode(gen_random_bytes(8), 'hex');
  begin
    insert into users (username, emp_id, salt, pin_hash) values (p_username, v_emp.id, v_salt, encode(digest(v_salt || ':' || p_pin || ':apt', 'sha256'), 'hex'));
  end;
  return json_build_object('ok', true);
end; $$;

create or replace function app_login(p_username text, p_pin text)
returns json language plpgsql security definer as $$
declare v_user users; v_emp employees; v_token text;
begin
  select * into v_user from users where lower(username) = lower(p_username);
  if v_user.id is null then return json_build_object('ok', false, 'error', 'Invalid username or PIN.'); end if;
  if v_user.locked_until is not null and v_user.locked_until > now() then
    return json_build_object('ok', false, 'error', 'Account temporarily locked after failed attempts. Try again in a few minutes.');
  end if;
  if not v_user.active then return json_build_object('ok', false, 'error', 'Account is disabled. Contact the Admin Manager.'); end if;
  if encode(digest(v_user.salt || ':' || p_pin || ':apt', 'sha256'), 'hex') <> v_user.pin_hash then
    update users set failed_attempts = coalesce(failed_attempts,0) + 1,
      locked_until = case when coalesce(failed_attempts,0) + 1 >= 5 then now() + interval '5 minutes' else locked_until end,
      failed_attempts = case when coalesce(failed_attempts,0) + 1 >= 5 then 0 else coalesce(failed_attempts,0) + 1 end
      where id = v_user.id;
    return json_build_object('ok', false, 'error', 'Invalid username or PIN.');
  end if;
  select * into v_emp from employees where id = v_user.emp_id;
  v_token := encode(gen_random_bytes(24), 'hex');
  update users set failed_attempts = 0, locked_until = null, last_login = now(), session_token = v_token, session_expires = now() + interval '12 hours' where id = v_user.id;
  return json_build_object('ok', true, 'token', v_token, 'user', json_build_object(
    'id', v_user.id, 'username', v_user.username, 'emp_id', v_emp.id, 'role', v_emp.user_type, 'name', v_emp.name,
    'email', v_emp.email, 'designation', v_emp.designation, 'branch', v_emp.branch, 'emp_code', v_emp.emp_code, 'menu_access', v_user.menu_access));
end; $$;

create or replace function app_me() returns json language plpgsql security definer as $$
declare v_id bigint := app_current_user_id(); v_user users; v_emp employees;
begin
  if v_id is null then return json_build_object('ok', false); end if;
  select * into v_user from users where id = v_id; select * into v_emp from employees where id = v_user.emp_id;
  return json_build_object('ok', true, 'user', json_build_object(
    'id', v_user.id, 'username', v_user.username, 'emp_id', v_emp.id, 'role', v_emp.user_type, 'name', v_emp.name,
    'email', v_emp.email, 'designation', v_emp.designation, 'branch', v_emp.branch, 'emp_code', v_emp.emp_code, 'menu_access', v_user.menu_access));
end; $$;

create or replace function app_logout() returns void language sql security definer as $$
  update users set session_token = null, session_expires = null where id = app_current_user_id();
$$;

create or replace function app_forgot(p_email text) returns json language plpgsql security definer as $$
declare v_id bigint;
begin
  update users set reset_requested = true where emp_id = (select id from employees where lower(email) = lower(p_email)) returning id into v_id;
  return json_build_object('ok', true, 'registered', v_id is not null);
end; $$;

create or replace function admin_list_users() returns json language plpgsql security definer as $$
begin
  if app_current_role() <> 'Admin Manager' then return json_build_object('ok', false, 'error', 'Unauthorized action.'); end if;
  return json_build_object('ok', true, 'users', (
    select coalesce(json_agg(json_build_object(
      'id', u.id, 'username', u.username, 'name', e.name, 'email', e.email, 'role', e.user_type, 'active', u.active,
      'last_login', u.last_login, 'reset_requested', u.reset_requested, 'locked', u.locked_until is not null and u.locked_until > now(),
      'menu_access', u.menu_access
    )), '[]'::json) from users u join employees e on e.id = u.emp_id));
end; $$;

create or replace function admin_set_menu_access(p_user_id bigint, p_menu_access jsonb) returns json language plpgsql security definer as $$
begin
  if app_current_role() <> 'Admin Manager' then return json_build_object('ok', false, 'error', 'Unauthorized action.'); end if;
  update users set menu_access = p_menu_access where id = p_user_id;
  return json_build_object('ok', true);
end; $$;

create or replace function admin_reset_pin(p_user_id bigint, p_pin text) returns json language plpgsql security definer as $$
declare v_salt text := encode(gen_random_bytes(8), 'hex');
begin
  if app_current_role() <> 'Admin Manager' then return json_build_object('ok', false, 'error', 'Unauthorized action.'); end if;
  update users set salt = v_salt, pin_hash = encode(digest(v_salt || ':' || p_pin || ':apt', 'sha256'), 'hex'),
    reset_requested = false, failed_attempts = 0, locked_until = null where id = p_user_id;
  return json_build_object('ok', true);
end; $$;

create or replace function admin_set_user_active(p_user_id bigint, p_active boolean) returns json language plpgsql security definer as $$
begin
  if app_current_role() <> 'Admin Manager' then return json_build_object('ok', false, 'error', 'Unauthorized action.'); end if;
  update users set active = p_active where id = p_user_id;
  return json_build_object('ok', true);
end; $$;

grant execute on function app_register, app_login, app_me, app_logout, app_forgot,
  admin_list_users, admin_reset_pin, admin_set_user_active, admin_set_menu_access to anon;
grant select, insert, update, delete on all tables in schema public to anon;
grant usage, select on all sequences in schema public to anon;

-- =====================================================================
-- Done. Next: Supabase Dashboard > Settings > API > copy "Project URL" and
-- the "anon public" key into this app's Settings > Database screen.
-- =====================================================================
