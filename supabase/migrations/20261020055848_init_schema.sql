-- ===========================================================================
-- Load Shedding & Electricity Tracker - initial schema
-- Created by: migration new init_schema
--
-- Conventions
--   * snake_case identifiers, table `users` (USER is reserved in Postgres)
--   * primary keys: bigint generated always as identity
--   * datetime columns: timestamptz, timestamps default to now()
--   * original column names `Timestamp` -> recorded_at, `Date` -> schedule_date
--   * created in dependency order
--   * ON DELETE: CASCADE for child rows of an area or user,
--                SET NULL for optional links (areas.substation_id,
--                users.auth_id, schedules.created_by_admin_id)
--   * every foreign key column is indexed
--   * Row Level Security enabled on every table
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. substations
-- ---------------------------------------------------------------------------
create table public.substations (
  substation_id bigint generated always as identity primary key,
  name          text        not null,
  location      text,
  capacity_mw   double precision          -- Postgres `float` (float8)
);

-- ---------------------------------------------------------------------------
-- 2. areas  (child of substations -> optional link, SET NULL)
-- ---------------------------------------------------------------------------
create table public.areas (
  area_id       bigint generated always as identity primary key,
  substation_id bigint references public.substations (substation_id)
                on delete set null,       -- optional link: area survives
  area_name     text        not null,
  city          text,
  zip_code      text,
  latitude      double precision,
  longitude     double precision,
  description   text
);

-- ---------------------------------------------------------------------------
-- 3. users  (child of areas -> CASCADE, links to Supabase Auth)
-- ---------------------------------------------------------------------------
create table public.users (
  user_id       bigint generated always as identity primary key,
  area_id       bigint      not null
                references public.areas (area_id)
                on delete cascade,        -- users belong to an area
  name          text        not null,
  email         text        not null unique,
  phone_number  text,
  password_hash text        not null,
  role          text        not null default 'consumer'
                constraint chk_users_role check (role in ('consumer', 'admin')),
  is_active     boolean     not null default true,
  created_at    timestamptz not null default now(),
  last_login    timestamptz,
  -- links the row to a Supabase Auth identity; optional -> SET NULL
  auth_id       uuid unique references auth.users (id)
                on delete set null
);

-- ---------------------------------------------------------------------------
-- 4. phase_information  (child of areas -> CASCADE)
--    `Timestamp` renamed to recorded_at
-- ---------------------------------------------------------------------------
create table public.phase_information (
  phase_id      bigint generated always as identity primary key,
  area_id       bigint      not null
                references public.areas (area_id)
                on delete cascade,
  phase_name    text        not null,
  reading_value double precision,
  shift_status  text,
  recorded_at   timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 5. voltage_readings  (child of areas -> CASCADE)
--    `Timestamp` renamed to recorded_at
-- ---------------------------------------------------------------------------
create table public.voltage_readings (
  reading_id    bigint generated always as identity primary key,
  area_id       bigint      not null
                references public.areas (area_id)
                on delete cascade,
  voltage_value double precision,
  status        text        not null
                constraint chk_voltage_readings_status
                check (status in ('normal', 'low', 'high')),
  recorded_at   timestamptz not null default now(),
  source_sensor text
);

-- ---------------------------------------------------------------------------
-- 6. outage_reports  (child of a user and of an area -> CASCADE)
-- ---------------------------------------------------------------------------
create table public.outage_reports (
  report_id     bigint generated always as identity primary key,
  user_id       bigint      not null
                references public.users (user_id)
                on delete cascade,
  area_id       bigint      not null
                references public.areas (area_id)
                on delete cascade,
  reported_at   timestamptz not null default now(),
  issue_type    text,
  description   text,
  is_verified   boolean     not null default false
);

-- ---------------------------------------------------------------------------
-- 7. admin_logs  (child of a user -> CASCADE)
-- ---------------------------------------------------------------------------
create table public.admin_logs (
  log_id            bigint generated always as identity primary key,
  admin_id          bigint      not null
                    references public.users (user_id)
                    on delete cascade,
  action_performed  text        not null,
  target_table      text,
  recorded_at       timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 8. appliances  (child of a user -> CASCADE)
-- ---------------------------------------------------------------------------
create table public.appliances (
  appliance_id            bigint generated always as identity primary key,
  user_id                 bigint      not null
                          references public.users (user_id)
                          on delete cascade,
  appliance_type          text        not null,
  max_voltage_tolerance   double precision not null,
  min_voltage_tolerance   double precision not null,
  constraint chk_appliances_voltage_tolerance
    check (min_voltage_tolerance < max_voltage_tolerance)
);

-- ---------------------------------------------------------------------------
-- 9. alerts  (child of a user -> CASCADE)
-- ---------------------------------------------------------------------------
create table public.alerts (
  alert_id        bigint generated always as identity primary key,
  user_id         bigint      not null
                  references public.users (user_id)
                  on delete cascade,
  alert_type      text,
  priority_level  text        not null
                  constraint chk_alerts_priority_level
                  check (priority_level in ('low', 'medium', 'high', 'critical')),
  message         text        not null,
  sent_at         timestamptz not null default now(),
  delivery_method text        not null
                  constraint chk_alerts_delivery_method
                  check (delivery_method in ('sms', 'email', 'push')),
  status          text        not null
                  constraint chk_alerts_status
                  check (status in ('pending', 'sent', 'failed', 'read'))
);

-- ---------------------------------------------------------------------------
-- 10. schedules  (child of areas -> CASCADE; admin link optional -> SET NULL)
--     `Date` renamed to schedule_date
-- ---------------------------------------------------------------------------
create table public.schedules (
  schedule_id         bigint generated always as identity primary key,
  area_id             bigint      not null
                      references public.areas (area_id)
                      on delete cascade,
  created_by_admin_id bigint
                      references public.users (user_id)
                      on delete set null,   -- optional link
  schedule_date       date        not null,
  start_time          time        not null,
  end_time            time        not null,
  duration_minutes    integer,
  status              text        not null
                      constraint chk_schedules_status
                      check (status in ('scheduled', 'active', 'completed', 'cancelled')),
  recurrence          text        not null
                      constraint chk_schedules_recurrence
                      check (recurrence in ('none', 'daily', 'weekly', 'monthly')),
  constraint chk_schedules_time_order check (end_time > start_time)
);

-- ---------------------------------------------------------------------------
-- Indexes - one on every foreign key column
-- ---------------------------------------------------------------------------
create index idx_areas_substation_id         on public.areas (substation_id);
create index idx_users_area_id               on public.users (area_id);
-- users.auth_id is a FK too, but its UNIQUE constraint already
-- creates the index users_auth_id_key on (auth_id).
create index idx_phase_information_area_id   on public.phase_information (area_id);
create index idx_voltage_readings_area_id    on public.voltage_readings (area_id);
create index idx_outage_reports_user_id      on public.outage_reports (user_id);
create index idx_outage_reports_area_id      on public.outage_reports (area_id);
create index idx_admin_logs_admin_id         on public.admin_logs (admin_id);
create index idx_appliances_user_id          on public.appliances (user_id);
create index idx_alerts_user_id              on public.alerts (user_id);
create index idx_schedules_area_id           on public.schedules (area_id);
create index idx_schedules_created_by_admin_id
                                              on public.schedules (created_by_admin_id);

-- ---------------------------------------------------------------------------
-- Row Level Security - enabled on every table
-- ---------------------------------------------------------------------------
alter table public.substations       enable row level security;
alter table public.areas             enable row level security;
alter table public.users             enable row level security;
alter table public.phase_information enable row level security;
alter table public.voltage_readings  enable row level security;
alter table public.outage_reports    enable row level security;
alter table public.admin_logs        enable row level security;
alter table public.appliances        enable row level security;
alter table public.alerts            enable row level security;
alter table public.schedules         enable row level security;

-- Helper predicates ----------------------------------------------------------
-- current_user_id(): resolves the signed-in user to its app row. Written as an
-- uncorrelated scalar subquery in policies so Postgres evaluates it once
-- (InitPlan) instead of once per row. It can never return another user's id.
-- is_admin(): true only when the signed-in user's row has role = 'admin'.
create or replace function public.current_user_id()
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select u.user_id
  from public.users u
  where u.auth_id = auth.uid()
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.users u
    where u.auth_id = auth.uid()
      and u.role = 'admin'
  )
$$;

revoke execute on function public.current_user_id() from public, anon;
revoke execute on function public.is_admin()        from public, anon;
grant execute on function public.current_user_id()  to authenticated, service_role;
grant execute on function public.is_admin()         to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Policies
-- ---------------------------------------------------------------------------

-- users: read / update only their own row -------------------------------
drop policy if exists users_select_own on public.users;
create policy users_select_own
  on public.users for select
  to authenticated
  using (auth_id = auth.uid());

drop policy if exists users_update_own on public.users;
create policy users_update_own
  on public.users for update
  to authenticated
  using (auth_id = auth.uid())
  with check (auth_id = auth.uid());

-- appliances: read / update only their own -------------------------------
drop policy if exists appliances_select_own on public.appliances;
create policy appliances_select_own
  on public.appliances for select
  to authenticated
  using (user_id = public.current_user_id());

drop policy if exists appliances_update_own on public.appliances;
create policy appliances_update_own
  on public.appliances for update
  to authenticated
  using (user_id = public.current_user_id())
  with check (user_id = public.current_user_id());

-- alerts: read / update only their own ------------------------------------
drop policy if exists alerts_select_own on public.alerts;
create policy alerts_select_own
  on public.alerts for select
  to authenticated
  using (user_id = public.current_user_id());

drop policy if exists alerts_update_own on public.alerts;
create policy alerts_update_own
  on public.alerts for update
  to authenticated
  using (user_id = public.current_user_id())
  with check (user_id = public.current_user_id());

-- outage_reports: read / update only their own -----------------------------
drop policy if exists outage_reports_select_own on public.outage_reports;
create policy outage_reports_select_own
  on public.outage_reports for select
  to authenticated
  using (user_id = public.current_user_id());

drop policy if exists outage_reports_update_own on public.outage_reports;
create policy outage_reports_update_own
  on public.outage_reports for update
  to authenticated
  using (user_id = public.current_user_id())
  with check (user_id = public.current_user_id());

-- Anyone authenticated may read these reference / telemetry tables ----------
drop policy if exists substations_select_authenticated on public.substations;
create policy substations_select_authenticated
  on public.substations for select
  to authenticated
  using (true);

drop policy if exists areas_select_authenticated on public.areas;
create policy areas_select_authenticated
  on public.areas for select
  to authenticated
  using (true);

drop policy if exists schedules_select_authenticated on public.schedules;
create policy schedules_select_authenticated
  on public.schedules for select
  to authenticated
  using (true);

drop policy if exists voltage_readings_select_authenticated on public.voltage_readings;
create policy voltage_readings_select_authenticated
  on public.voltage_readings for select
  to authenticated
  using (true);

drop policy if exists phase_information_select_authenticated on public.phase_information;
create policy phase_information_select_authenticated
  on public.phase_information for select
  to authenticated
  using (true);

-- Admins only may WRITE (insert / update / delete) these tables -------------
-- Read access is granted separately above (authenticated read on substations,
-- areas, schedules, voltage_readings, phase_information).

-- substations ----------------------------------------------------------------
drop policy if exists substations_admin_insert on public.substations;
create policy substations_admin_insert
  on public.substations for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists substations_admin_update on public.substations;
create policy substations_admin_update
  on public.substations for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists substations_admin_delete on public.substations;
create policy substations_admin_delete
  on public.substations for delete
  to authenticated
  using (public.is_admin());

-- areas ----------------------------------------------------------------------
drop policy if exists areas_admin_insert on public.areas;
create policy areas_admin_insert
  on public.areas for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists areas_admin_update on public.areas;
create policy areas_admin_update
  on public.areas for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists areas_admin_delete on public.areas;
create policy areas_admin_delete
  on public.areas for delete
  to authenticated
  using (public.is_admin());

-- schedules ------------------------------------------------------------------
drop policy if exists schedules_admin_insert on public.schedules;
create policy schedules_admin_insert
  on public.schedules for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists schedules_admin_update on public.schedules;
create policy schedules_admin_update
  on public.schedules for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists schedules_admin_delete on public.schedules;
create policy schedules_admin_delete
  on public.schedules for delete
  to authenticated
  using (public.is_admin());

-- voltage_readings -----------------------------------------------------------
drop policy if exists voltage_readings_admin_insert on public.voltage_readings;
create policy voltage_readings_admin_insert
  on public.voltage_readings for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists voltage_readings_admin_update on public.voltage_readings;
create policy voltage_readings_admin_update
  on public.voltage_readings for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists voltage_readings_admin_delete on public.voltage_readings;
create policy voltage_readings_admin_delete
  on public.voltage_readings for delete
  to authenticated
  using (public.is_admin());

-- phase_information ----------------------------------------------------------
drop policy if exists phase_information_admin_insert on public.phase_information;
create policy phase_information_admin_insert
  on public.phase_information for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists phase_information_admin_update on public.phase_information;
create policy phase_information_admin_update
  on public.phase_information for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists phase_information_admin_delete on public.phase_information;
create policy phase_information_admin_delete
  on public.phase_information for delete
  to authenticated
  using (public.is_admin());

-- admin_logs (readable + writable by admins only) ----------------------------
drop policy if exists admin_logs_admin_select on public.admin_logs;
create policy admin_logs_admin_select
  on public.admin_logs for select
  to authenticated
  using (public.is_admin());

drop policy if exists admin_logs_admin_insert on public.admin_logs;
create policy admin_logs_admin_insert
  on public.admin_logs for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists admin_logs_admin_update on public.admin_logs;
create policy admin_logs_admin_update
  on public.admin_logs for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists admin_logs_admin_delete on public.admin_logs;
create policy admin_logs_admin_delete
  on public.admin_logs for delete
  to authenticated
  using (public.is_admin());
