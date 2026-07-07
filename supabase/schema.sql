-- =========================================================================
-- RAJUTAKSI - SUPABASE SCHEMA
-- =========================================================================
-- Cara pakai:
-- 1. Buka Supabase Dashboard -> project kamu -> SQL Editor -> New Query
-- 2. Copy-paste SELURUH isi file ini, lalu klik "Run"
-- 3. Setelah selesai, buka Storage -> buat 3 bucket PUBLIC:
--    - avatars
--    - event-posters
--    - chat-attachments
--   (Storage -> New Bucket -> centang "Public bucket")
-- =========================================================================

-- Ekstensi yang dibutuhkan
create extension if not exists "uuid-ossp";

-- -------------------------------------------------------------------------
-- 1. PROFILES  (menyimpan data user + roles sebagai ARRAY -> mendukung multi peran)
-- -------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text not null default '',
  phone text,
  bio text,
  avatar_url text,
  roles text[] not null default array['relawan'],       -- contoh: {relawan,sponsor}
  active_role text not null default 'relawan',           -- peran yang sedang ditampilkan
  interests text[] not null default array[]::text[],
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Profiles are viewable by everyone"
  on public.profiles for select
  using (true);

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- -------------------------------------------------------------------------
-- 2. EVENTS  (dibuat oleh user dengan peran organisasi)
-- -------------------------------------------------------------------------
create table if not exists public.events (
  id uuid primary key default uuid_generate_v4(),
  organizer_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null default '',
  sdg_category text not null default '',        -- contoh: "SDG 13"
  category_label text not null default '',      -- contoh: "Lingkungan"
  event_date timestamptz,
  location text not null default '',
  meeting_point text default '',
  quota int not null default 20,
  filled_count int not null default 0,
  poster_url text,
  need_sponsor boolean not null default false,
  target_funding numeric not null default 0,
  collected_funding numeric not null default 0,
  status text not null default 'published',     -- draft | published | ongoing | done
  created_at timestamptz not null default now()
);

alter table public.events enable row level security;

create policy "Events are viewable by everyone"
  on public.events for select
  using (true);

create policy "Organizers can insert their own events"
  on public.events for insert
  with check (auth.uid() = organizer_id);

create policy "Organizers can update their own events"
  on public.events for update
  using (auth.uid() = organizer_id);

create policy "Organizers can delete their own events"
  on public.events for delete
  using (auth.uid() = organizer_id);

-- -------------------------------------------------------------------------
-- 3. REGISTRATIONS  (relawan mendaftar ke sebuah event)
-- -------------------------------------------------------------------------
create table if not exists public.registrations (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid not null references public.events(id) on delete cascade,
  volunteer_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending',  -- pending | approved | rejected | completed
  registered_at timestamptz not null default now(),
  unique (event_id, volunteer_id)
);

alter table public.registrations enable row level security;

create policy "Registrations viewable by involved parties"
  on public.registrations for select
  using (auth.uid() = volunteer_id or auth.uid() in (
    select organizer_id from public.events where events.id = registrations.event_id
  ));

create policy "Volunteers can register themselves"
  on public.registrations for insert
  with check (auth.uid() = volunteer_id);

-- Trigger: otomatis menambah filled_count di events saat ada registrasi baru
create or replace function public.increment_filled_count()
returns trigger as $$
begin
  update public.events set filled_count = filled_count + 1 where id = new.event_id;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_increment_filled_count on public.registrations;
create trigger trg_increment_filled_count
  after insert on public.registrations
  for each row execute function public.increment_filled_count();

-- -------------------------------------------------------------------------
-- 4. SPONSORSHIPS  (sponsor mengajukan penawaran ke sebuah event)
-- -------------------------------------------------------------------------
create table if not exists public.sponsorships (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid not null references public.events(id) on delete cascade,
  sponsor_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric not null default 0,
  message text default '',
  status text not null default 'pending',  -- pending | accepted | rejected
  created_at timestamptz not null default now()
);

alter table public.sponsorships enable row level security;

create policy "Sponsorships viewable by involved parties"
  on public.sponsorships for select
  using (auth.uid() = sponsor_id or auth.uid() in (
    select organizer_id from public.events where events.id = sponsorships.event_id
  ));

create policy "Sponsors can submit proposals"
  on public.sponsorships for insert
  with check (auth.uid() = sponsor_id);

-- Trigger: otomatis menambah collected_funding saat sponsorship diterima
create or replace function public.handle_sponsorship_accept()
returns trigger as $$
begin
  if new.status = 'accepted' and old.status is distinct from 'accepted' then
    update public.events set collected_funding = collected_funding + new.amount where id = new.event_id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_sponsorship_accept on public.sponsorships;
create trigger trg_sponsorship_accept
  after update on public.sponsorships
  for each row execute function public.handle_sponsorship_accept();

-- -------------------------------------------------------------------------
-- 5. CONVERSATIONS & MESSAGES (chat antar relawan / organisasi / sponsor)
-- -------------------------------------------------------------------------
create table if not exists public.conversations (
  id uuid primary key default uuid_generate_v4(),
  user_a uuid not null references public.profiles(id) on delete cascade,
  user_b uuid not null references public.profiles(id) on delete cascade,
  last_message text,
  last_message_at timestamptz default now(),
  created_at timestamptz not null default now(),
  unique (user_a, user_b)
);

alter table public.conversations enable row level security;

create policy "Conversations viewable by participants"
  on public.conversations for select
  using (auth.uid() = user_a or auth.uid() = user_b);

create policy "Users can create conversations they participate in"
  on public.conversations for insert
  with check (auth.uid() = user_a or auth.uid() = user_b);

create policy "Participants can update conversation metadata"
  on public.conversations for update
  using (auth.uid() = user_a or auth.uid() = user_b);

create table if not exists public.messages (
  id uuid primary key default uuid_generate_v4(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null default '',
  attachment_url text,
  attachment_name text,
  created_at timestamptz not null default now()
);

alter table public.messages enable row level security;

create policy "Messages viewable by conversation participants"
  on public.messages for select
  using (auth.uid() in (
    select user_a from public.conversations where conversations.id = messages.conversation_id
    union
    select user_b from public.conversations where conversations.id = messages.conversation_id
  ));

create policy "Participants can send messages"
  on public.messages for insert
  with check (auth.uid() = sender_id);

-- Aktifkan realtime untuk tabel messages (supaya chat live update)
alter publication supabase_realtime add table public.messages;

-- =========================================================================
-- SEED DATA (DATA CONTOH) — supaya aplikasi tidak kosong saat pertama dicoba
-- =========================================================================
-- CATATAN PENTING:
-- Supabase Auth (auth.users) tidak bisa diisi langsung lewat SQL Editor biasa.
-- Jadi untuk demo/seed, kita buat beberapa "organizer" & "sponsor" dummy
-- LANGSUNG di tabel profiles dengan id acak (uuid statis di bawah),
-- TANPA menghubungkannya ke auth.users. Ini cukup untuk menampilkan
-- data (event, sponsor, dsb) di UI, tapi akun ini tidak bisa dipakai login.
--
-- Supaya foreign key profiles.id -> auth.users(id) tidak menolak insert,
-- jalankan blok berikut yang MENONAKTIFKAN sementara constraint tsb khusus
-- untuk proses seeding, lalu kita insert manual.
-- -------------------------------------------------------------------------

alter table public.profiles drop constraint if exists profiles_id_fkey;

insert into public.profiles (id, full_name, email, roles, active_role, avatar_url, bio, interests) values
  ('11111111-1111-1111-1111-111111111111', 'Yayasan Hijau Nusantara', 'contact@hijaunusantara.org', array['organisasi'], 'organisasi', null, 'Organisasi lingkungan fokus restorasi ekosistem pesisir.', array['Lingkungan']),
  ('22222222-2222-2222-2222-222222222222', 'Green Horizon Team', 'hello@greenhorizon.id', array['organisasi'], 'organisasi', null, 'Komunitas relawan lingkungan dan edukasi.', array['Lingkungan','Pendidikan']),
  ('33333333-3333-3333-3333-333333333333', 'Komunitas Peduli Lansia', 'info@pedulilansia.id', array['organisasi'], 'organisasi', null, 'Fokus pada kesejahteraan lansia di perkotaan.', array['Kesehatan']),
  ('44444444-4444-4444-4444-444444444444', 'Global Corp', 'csr@globalcorp.com', array['sponsor'], 'sponsor', null, 'Perusahaan multinasional dengan program CSR aktif.', array['Lingkungan','Pendidikan']),
  ('55555555-5555-5555-5555-555555555555', 'Siti Aminah', 'siti.aminah@mail.com', array['relawan'], 'relawan', null, 'Relawan aktif kegiatan lingkungan.', array['Lingkungan']),
  ('66666666-6666-6666-6666-666666666666', 'Budi Santoso', 'budi.santoso@mail.com', array['relawan'], 'relawan', null, 'Suka kegiatan sosial akhir pekan.', array['Sosial'])
on conflict (id) do nothing;

-- Event contoh (mengikuti kategori & tampilan di UI)
insert into public.events (id, organizer_id, title, description, sdg_category, category_label, event_date, location, meeting_point, quota, filled_count, need_sponsor, target_funding, collected_funding, status, created_at) values
  ('aaaaaaa1-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   'Restorasi Mangrove Pesisir Pantai Indah',
   'Bergabunglah bersama kami dalam upaya memulihkan ekosistem pesisir melalui penanaman 1.000 bibit mangrove. Kegiatan ini bukan hanya sekadar menanam, tetapi juga mengedukasi masyarakat lokal tentang pentingnya blue carbon bagi mitigasi perubahan iklim global.',
   'SDG 13', 'Lingkungan', now() + interval '10 days', 'Pesisir Pantai Indah, Jakarta Utara', 'Dermaga Utama, Jam 07.30 WIB',
   30, 12, true, 10000000, 4200000, 'published', now() - interval '5 days'),

  ('aaaaaaa1-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222',
   'Reboisasi Hutan Kota Malang',
   'Meningkatkan resapan air dan area terbuka hijau di kawasan urban Malang melalui penanaman ribuan bibit pohon lokal bersama warga sekitar.',
   'SDG 13', 'Lingkungan', now() + interval '20 days', 'Malang, Jawa Timur', 'Balai Kota Malang',
   50, 18, true, 50000000, 20000000, 'published', now() - interval '3 days'),

  ('aaaaaaa1-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222',
   'Literasi Digital Pelosok NTT',
   'Penyediaan perangkat laptop dan pelatihan coding dasar untuk anak-anak sekolah dasar di pelosok Nusa Tenggara Timur.',
   'SDG 4', 'Pendidikan', now() + interval '25 days', 'Kupang, NTT', 'SDN 01 Kupang Tengah',
   15, 6, true, 120000000, 85000000, 'published', now() - interval '2 days'),

  ('aaaaaaa1-0000-0000-0000-000000000004', '33333333-3333-3333-3333-333333333333',
   'Pangan Sehat untuk Lansia',
   'Distribusi paket makanan sehat dan pemeriksaan kesehatan gratis bagi lansia di wilayah perkotaan yang kurang terjangkau layanan.',
   'SDG 3', 'Kesehatan', now() - interval '15 days', 'Jakarta Selatan', 'Posyandu Melati',
   20, 20, false, 0, 0, 'done', now() - interval '30 days'),

  ('aaaaaaa1-0000-0000-0000-000000000005', '22222222-2222-2222-2222-222222222222',
   'Pembersihan Sampah Sungai Ciliwung',
   'Aksi bersih-bersih rutin di bantaran sungai Ciliwung bersama komunitas lokal untuk mengurangi pencemaran dan risiko banjir.',
   'SDG 6', 'Lingkungan', now() + interval '1 days', 'Jakarta', 'Titik Kumpul Jembatan Kalibata',
   40, 24, false, 0, 0, 'published', now() - interval '1 days'),

  ('aaaaaaa1-0000-0000-0000-000000000006', '22222222-2222-2222-2222-222222222222',
   'Workshop Pengolahan Limbah Tekstil Rumah Tangga',
   'Pelatihan daur ulang limbah tekstil rumah tangga menjadi produk bernilai jual untuk mendukung ekonomi sirkular.',
   'SDG 12', 'Lingkungan', null, 'Bandung, Jawa Barat', '',
   25, 0, false, 0, 0, 'draft', now())
on conflict (id) do nothing;

-- Registrasi contoh
insert into public.registrations (event_id, volunteer_id, status) values
  ('aaaaaaa1-0000-0000-0000-000000000001', '55555555-5555-5555-5555-555555555555', 'approved'),
  ('aaaaaaa1-0000-0000-0000-000000000002', '66666666-6666-6666-6666-666666666666', 'approved')
on conflict do nothing;

-- Sponsorship contoh
insert into public.sponsorships (event_id, sponsor_id, amount, message, status) values
  ('aaaaaaa1-0000-0000-0000-000000000002', '44444444-4444-4444-4444-444444444444', 20000000, 'Kami tertarik mendukung reboisasi ini sebagai bagian dari program CSR lingkungan tahunan kami.', 'accepted')
on conflict do nothing;

-- Percakapan & pesan contoh
insert into public.conversations (id, user_a, user_b, last_message, last_message_at) values
  ('bbbbbbb1-0000-0000-0000-000000000001', '55555555-5555-5555-5555-555555555555', '11111111-1111-1111-1111-111111111111',
   'Bagaimana progres penanamannya?', now() - interval '2 hours')
on conflict do nothing;

insert into public.messages (conversation_id, sender_id, content, created_at) values
  ('bbbbbbb1-0000-0000-0000-000000000001', '55555555-5555-5555-5555-555555555555', 'Halo! Saya sudah daftar untuk kegiatan mangrove minggu depan.', now() - interval '3 hours'),
  ('bbbbbbb1-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Terima kasih sudah mendaftar! Sampai jumpa di lokasi ya.', now() - interval '2 hours 30 minutes'),
  ('bbbbbbb1-0000-0000-0000-000000000001', '55555555-5555-5555-5555-555555555555', 'Bagaimana progres penanamannya?', now() - interval '2 hours')
on conflict do nothing;

-- =========================================================================
-- SELESAI. Setelah di-run, cek tab "Table Editor" di Supabase untuk
-- memastikan data event & profil contoh sudah muncul.
-- =========================================================================
