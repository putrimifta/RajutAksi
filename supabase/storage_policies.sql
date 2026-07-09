-- =========================================================================
-- TAMBAHAN: STORAGE POLICIES untuk upload foto (poster event, avatar, chat)
-- =========================================================================
-- Jalankan file INI SAJA di SQL Editor Supabase (tidak perlu jalankan ulang
-- schema.sql yang lama, karena isinya akan bentrok "already exists").
--
-- Syarat: bucket avatars, event-posters, dan chat-attachments sudah dibuat
-- lewat menu Storage sebelumnya.
-- =========================================================================

create policy "Public read access for avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Authenticated users can upload avatars"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and auth.role() = 'authenticated');

create policy "Users can update their own avatar uploads"
  on storage.objects for update
  using (bucket_id = 'avatars' and auth.role() = 'authenticated');

create policy "Public read access for event posters"
  on storage.objects for select
  using (bucket_id = 'event-posters');

create policy "Authenticated users can upload event posters"
  on storage.objects for insert
  with check (bucket_id = 'event-posters' and auth.role() = 'authenticated');

create policy "Users can update their own event poster uploads"
  on storage.objects for update
  using (bucket_id = 'event-posters' and auth.role() = 'authenticated');

create policy "Public read access for chat attachments"
  on storage.objects for select
  using (bucket_id = 'chat-attachments');

create policy "Authenticated users can upload chat attachments"
  on storage.objects for insert
  with check (bucket_id = 'chat-attachments' and auth.role() = 'authenticated');
