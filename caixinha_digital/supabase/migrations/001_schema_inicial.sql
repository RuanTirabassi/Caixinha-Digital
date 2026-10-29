-- Caixinha Digital — banco de dados (já aplicado no projeto Supabase "caixinha-digital").
-- Guardado aqui para documentação e para recriar o banco se precisar.

-- ============ TABELAS ============
create table public.idosos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  sobrenome text,
  tratamento text not null default 'nenhum' check (tratamento in ('nenhum','senhor','senhora')),
  whatsapp text,
  codigo_acesso text not null unique,          -- código do idoso (6 dígitos, sem senha)
  codigo_cuidador text not null unique,        -- código para outro cuidador entrar
  hora_cafe time not null default '08:00',
  hora_almoco time not null default '12:00',
  hora_jantar time not null default '20:00',
  tamanho_letra text not null default 'grande' check (tamanho_letra in ('normal','grande','muito_grande')),
  som boolean not null default true,
  vibracao boolean not null default true,
  aviso_atraso boolean not null default true,
  resumo_diario boolean not null default true,
  created_at timestamptz not null default now()
);

-- quem pode acessar cada idoso (cuidador = edita; idoso = só usa)
create table public.acessos (
  user_id uuid not null references auth.users(id) on delete cascade,
  idoso_id uuid not null references public.idosos(id) on delete cascade,
  papel text not null check (papel in ('cuidador','idoso')),
  created_at timestamptz not null default now(),
  primary key (user_id, idoso_id)
);

create table public.medicamentos (
  id uuid primary key default gen_random_uuid(),
  idoso_id uuid not null references public.idosos(id) on delete cascade,
  nome text not null,
  dose_texto text not null,
  finalidade text,
  foto_path text,
  formato text check (formato in ('redondo','capsula','oval','comprido')),
  cor text,
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.horarios (
  id uuid primary key default gen_random_uuid(),
  medicamento_id uuid not null references public.medicamentos(id) on delete cascade,
  hora time not null,
  turno text not null check (turno in ('manha','almoco','noite'))
);

create table public.doses (
  id uuid primary key default gen_random_uuid(),
  horario_id uuid not null references public.horarios(id) on delete cascade,
  data date not null default (now() at time zone 'America/Sao_Paulo')::date,
  tomado_em timestamptz not null default now(),
  registrado_por uuid default auth.uid() references auth.users(id) on delete set null,
  unique (horario_id, data)
);

create table public.documentos (
  id uuid primary key default gen_random_uuid(),
  idoso_id uuid not null references public.idosos(id) on delete cascade,
  tipo text not null check (tipo in ('receita','exame')),
  titulo text not null,
  origem text,
  data date,
  arquivo_path text,
  created_at timestamptz not null default now()
);

create table public.tentativas_codigo (
  id bigint generated always as identity primary key,
  user_id uuid not null,
  em timestamptz not null default now()
);
comment on table public.tentativas_codigo is 'Sem policies de propósito: só funções security definer acessam.';

create index on public.acessos (idoso_id);
create index on public.medicamentos (idoso_id);
create index on public.horarios (medicamento_id);
create index on public.doses (data);
create index on public.documentos (idoso_id);
create index on public.tentativas_codigo (user_id, em);

-- ============ FUNÇÕES AUXILIARES ============
create or replace function public.pode_ver(p_idoso uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.acessos a where a.idoso_id = p_idoso and a.user_id = (select auth.uid()));
$$;

create or replace function public.pode_editar(p_idoso uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.acessos a where a.idoso_id = p_idoso and a.user_id = (select auth.uid()) and a.papel = 'cuidador');
$$;

create or replace function public.idoso_do_horario(p_horario uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select m.idoso_id from public.horarios h join public.medicamentos m on m.id = h.medicamento_id where h.id = p_horario;
$$;

create or replace function public.gerar_codigo(p_tamanho int) returns text
language plpgsql volatile set search_path = '' as $$
declare c text;
begin
  loop
    c := lpad((floor(random() * power(10, p_tamanho)))::bigint::text, p_tamanho, '0');
    exit when not exists (select 1 from public.idosos where codigo_acesso = c or codigo_cuidador = c);
  end loop;
  return c;
end $$;

-- anti força-bruta: 5 códigos errados a cada 10 min
create or replace function public.checar_tentativas() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if (select count(*) from public.tentativas_codigo
      where user_id = (select auth.uid()) and em > now() - interval '10 minutes') >= 5 then
    raise exception 'Muitas tentativas. Aguarde alguns minutos.';
  end if;
end $$;

-- ============ RPCs ============
create or replace function public.criar_idoso(p_nome text, p_sobrenome text, p_tratamento text, p_whatsapp text)
returns public.idosos language plpgsql security definer set search_path = '' as $$
declare novo public.idosos;
begin
  if auth.uid() is null then raise exception 'Faça login primeiro.'; end if;
  insert into public.idosos (nome, sobrenome, tratamento, whatsapp, codigo_acesso, codigo_cuidador)
  values (p_nome, p_sobrenome, coalesce(p_tratamento,'nenhum'), p_whatsapp, public.gerar_codigo(6), public.gerar_codigo(8))
  returning * into novo;
  insert into public.acessos (user_id, idoso_id, papel) values (auth.uid(), novo.id, 'cuidador');
  return novo;
end $$;

create or replace function public.vincular_cuidador(p_codigo text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Faça login primeiro.'; end if;
  perform public.checar_tentativas();
  select id into v_id from public.idosos where codigo_cuidador = trim(p_codigo);
  if v_id is null then
    insert into public.tentativas_codigo (user_id) values (auth.uid());
    raise exception 'Código não encontrado.';
  end if;
  insert into public.acessos (user_id, idoso_id, papel) values (auth.uid(), v_id, 'cuidador')
  on conflict (user_id, idoso_id) do update set papel = 'cuidador';
  return v_id;
end $$;

create or replace function public.entrar_como_idoso(p_codigo text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Sessão não iniciada.'; end if;
  perform public.checar_tentativas();
  select id into v_id from public.idosos where codigo_acesso = trim(p_codigo);
  if v_id is null then
    insert into public.tentativas_codigo (user_id) values (auth.uid());
    raise exception 'Código não encontrado.';
  end if;
  insert into public.acessos (user_id, idoso_id, papel) values (auth.uid(), v_id, 'idoso')
  on conflict (user_id, idoso_id) do nothing;
  return v_id;
end $$;

create or replace function public.novo_codigo_idoso(p_idoso uuid) returns text
language plpgsql security definer set search_path = '' as $$
declare c text;
begin
  if not public.pode_editar(p_idoso) then raise exception 'Sem permissão.'; end if;
  c := public.gerar_codigo(6);
  update public.idosos set codigo_acesso = c where id = p_idoso;
  delete from public.acessos where idoso_id = p_idoso and papel = 'idoso';
  return c;
end $$;

create or replace function public.doses_de_hoje(p_idoso uuid)
returns table (horario_id uuid, medicamento_id uuid, nome text, dose_texto text, finalidade text,
               foto_path text, formato text, cor text, hora time, turno text,
               dose_id uuid, tomado_em timestamptz, status text)
language sql stable security definer set search_path = '' as $$
  with agora as (select (now() at time zone 'America/Sao_Paulo') as t)
  select h.id, m.id, m.nome, m.dose_texto, m.finalidade, m.foto_path, m.formato, m.cor, h.hora, h.turno,
         d.id, d.tomado_em,
         case
           when d.id is not null then 'tomado'
           when (select t::time from agora) > h.hora + interval '60 minutes' then 'atrasado'
           when (select t::time from agora) >= h.hora - interval '60 minutes' then 'agora'
           else 'futuro'
         end
  from public.medicamentos m
  join public.horarios h on h.medicamento_id = m.id
  left join public.doses d on d.horario_id = h.id and d.data = (select t::date from agora)
  where m.idoso_id = p_idoso and m.ativo and public.pode_ver(p_idoso)
  order by h.hora, m.nome;
$$;

-- ============ RLS ============
alter table public.idosos enable row level security;
alter table public.acessos enable row level security;
alter table public.medicamentos enable row level security;
alter table public.horarios enable row level security;
alter table public.doses enable row level security;
alter table public.documentos enable row level security;
alter table public.tentativas_codigo enable row level security;

create policy "ver idoso" on public.idosos for select to authenticated using (public.pode_ver(id));
create policy "editar idoso" on public.idosos for update to authenticated using (public.pode_editar(id)) with check (public.pode_editar(id));

create policy "ver acessos" on public.acessos for select to authenticated
  using (user_id = (select auth.uid()) or public.pode_editar(idoso_id));
create policy "remover acessos" on public.acessos for delete to authenticated
  using (user_id = (select auth.uid()) or public.pode_editar(idoso_id));

create policy "ver remedios" on public.medicamentos for select to authenticated using (public.pode_ver(idoso_id));
create policy "criar remedios" on public.medicamentos for insert to authenticated with check (public.pode_editar(idoso_id));
create policy "editar remedios" on public.medicamentos for update to authenticated using (public.pode_editar(idoso_id)) with check (public.pode_editar(idoso_id));
create policy "apagar remedios" on public.medicamentos for delete to authenticated using (public.pode_editar(idoso_id));

create policy "ver horarios" on public.horarios for select to authenticated
  using (public.pode_ver((select m.idoso_id from public.medicamentos m where m.id = medicamento_id)));
create policy "gerenciar horarios" on public.horarios for all to authenticated
  using (public.pode_editar((select m.idoso_id from public.medicamentos m where m.id = medicamento_id)))
  with check (public.pode_editar((select m.idoso_id from public.medicamentos m where m.id = medicamento_id)));

create policy "ver doses" on public.doses for select to authenticated using (public.pode_ver(public.idoso_do_horario(horario_id)));
create policy "marcar dose" on public.doses for insert to authenticated with check (public.pode_ver(public.idoso_do_horario(horario_id)));
create policy "desfazer dose" on public.doses for delete to authenticated using (public.pode_ver(public.idoso_do_horario(horario_id)));

create policy "ver documentos" on public.documentos for select to authenticated using (public.pode_ver(idoso_id));
create policy "gerenciar documentos" on public.documentos for all to authenticated
  using (public.pode_editar(idoso_id)) with check (public.pode_editar(idoso_id));

-- permissões das funções
revoke execute on function public.gerar_codigo(int), public.checar_tentativas() from public, anon, authenticated;
revoke execute on function public.criar_idoso(text,text,text,text), public.vincular_cuidador(text),
  public.entrar_como_idoso(text), public.novo_codigo_idoso(uuid), public.doses_de_hoje(uuid),
  public.pode_ver(uuid), public.pode_editar(uuid), public.idoso_do_horario(uuid) from public, anon;
grant execute on function public.criar_idoso(text,text,text,text), public.vincular_cuidador(text),
  public.entrar_como_idoso(text), public.novo_codigo_idoso(uuid), public.doses_de_hoje(uuid),
  public.pode_ver(uuid), public.pode_editar(uuid), public.idoso_do_horario(uuid) to authenticated;

-- tempo real: painel do cuidador atualiza quando o idoso confirma
alter publication supabase_realtime add table public.doses;

-- ============ STORAGE (pasta = id do idoso) ============
insert into storage.buckets (id, name, public) values ('arquivos', 'arquivos', false) on conflict do nothing;

create policy "ver arquivos" on storage.objects for select to authenticated
  using (bucket_id = 'arquivos' and public.pode_ver(((storage.foldername(name))[1])::uuid));
create policy "enviar arquivos" on storage.objects for insert to authenticated
  with check (bucket_id = 'arquivos' and public.pode_editar(((storage.foldername(name))[1])::uuid));
create policy "apagar arquivos" on storage.objects for delete to authenticated
  using (bucket_id = 'arquivos' and public.pode_editar(((storage.foldername(name))[1])::uuid));
