-- Caixinha Digital — telas novas do protótipo no Figma (já aplicado no Supabase).
-- Só adiciona colunas, tabela e funções; nenhum dado existente é apagado.

-- ============ COLUNAS NOVAS ============
alter table public.idosos
  -- código do idoso: vale 10 minutos e só entra uma vez
  add column codigo_expira_em timestamptz not null default (now() + interval '10 minutes'),
  -- Config / 02 Avisos
  add column aviso_minutos int not null default 60 check (aviso_minutos in (30, 60, 120)),
  add column aviso_canal text not null default 'whatsapp' check (aviso_canal in ('whatsapp', 'app', 'ambos')),
  -- Config / 03 Celular: "Repetir lembrete"
  add column repetir_lembrete boolean not null default false;

-- Cadastro de remédio: "Cor 1" (coluna cor) e "Cor 2"
alter table public.medicamentos add column cor2 text;

-- Cadastro de receita/exame: "Descrição (opcional)"
alter table public.documentos add column descricao text;

-- Config / 04 Acesso e aparelhos + Config / 02 Quem recebe
alter table public.acessos
  add column aparelho text,
  add column ultimo_uso timestamptz not null default now(),
  add column recebe_avisos boolean not null default true;

-- ============ CUIDADOR (Cuidador / 03 Dados do cuidador) ============
create table public.cuidadores (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  nome text not null,
  sobrenome text,
  whatsapp text,
  autoriza_whatsapp boolean not null default true, -- Privacidade: "Avisos pelo WhatsApp"
  created_at timestamptz not null default now()
);
alter table public.cuidadores enable row level security;
create policy "ver meu perfil" on public.cuidadores for select to authenticated
  using (user_id = (select auth.uid()));
create policy "criar meu perfil" on public.cuidadores for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "editar meu perfil" on public.cuidadores for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- ============ FUNÇÕES ============
drop function public.entrar_como_idoso(text);
create function public.entrar_como_idoso(p_codigo text, p_aparelho text default null) returns uuid
language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Sessão não iniciada.'; end if;
  perform public.checar_tentativas();
  select id into v_id from public.idosos
   where codigo_acesso = trim(p_codigo) and codigo_expira_em > now();
  if v_id is null then
    insert into public.tentativas_codigo (user_id) values (auth.uid());
    raise exception 'Código não encontrado ou vencido. Peça um novo a quem cuida de você.';
  end if;
  -- uso único: depois que alguém entra, o código deixa de valer
  update public.idosos set codigo_expira_em = now() where id = v_id;
  insert into public.acessos (user_id, idoso_id, papel, aparelho) values (auth.uid(), v_id, 'idoso', p_aparelho)
  on conflict (user_id, idoso_id) do update
    set aparelho = coalesce(excluded.aparelho, public.acessos.aparelho), ultimo_uso = now();
  return v_id;
end $$;

-- "Gerar novo código": vale 10 min; não desconecta mais os celulares
-- (agora cada celular é desconectado na lista de aparelhos)
create or replace function public.novo_codigo_idoso(p_idoso uuid) returns text
language plpgsql security definer set search_path = '' as $$
declare c text;
begin
  if not public.pode_editar(p_idoso) then raise exception 'Sem permissão.'; end if;
  c := public.gerar_codigo(6);
  update public.idosos set codigo_acesso = c, codigo_expira_em = now() + interval '10 minutes'
   where id = p_idoso;
  return c;
end $$;

-- "atrasado" usa o tempo escolhido em Avisos (30 min, 1 h ou 2 h).
-- Compara em minutos do dia para não "dar a volta" na meia-noite.
-- (agora também devolve cor2, para desenhar o comprimido nas duas cores)
drop function public.doses_de_hoje(uuid);
create function public.doses_de_hoje(p_idoso uuid)
returns table (horario_id uuid, medicamento_id uuid, nome text, dose_texto text, finalidade text,
               foto_path text, formato text, cor text, cor2 text, hora time, turno text,
               dose_id uuid, tomado_em timestamptz, status text)
language sql stable security definer set search_path = '' as $$
  with agora as (select (now() at time zone 'America/Sao_Paulo') as t),
       m as (select extract(hour from t)::int * 60 + extract(minute from t)::int as min_agora from agora),
       cfg as (select aviso_minutos from public.idosos where id = p_idoso)
  select h.id, md.id, md.nome, md.dose_texto, md.finalidade, md.foto_path, md.formato, md.cor, md.cor2, h.hora, h.turno,
         d.id, d.tomado_em,
         case
           when d.id is not null then 'tomado'
           when (select min_agora from m) > extract(hour from h.hora)::int * 60 + extract(minute from h.hora)::int
                                              + (select aviso_minutos from cfg) then 'atrasado'
           when (select min_agora from m) >= extract(hour from h.hora)::int * 60 + extract(minute from h.hora)::int - 60
                then 'agora'
           else 'futuro'
         end
  from public.medicamentos md
  join public.horarios h on h.medicamento_id = md.id
  left join public.doses d on d.horario_id = h.id and d.data = (select t::date from agora)
  where md.idoso_id = p_idoso and md.ativo and public.pode_ver(p_idoso)
  order by h.hora, md.nome;
$$;

-- o app avisa que está em uso (lista "Celulares conectados")
create function public.registrar_uso(p_idoso uuid, p_aparelho text) returns void
language sql security definer set search_path = '' as $$
  update public.acessos set ultimo_uso = now(), aparelho = coalesce(p_aparelho, aparelho)
   where user_id = (select auth.uid()) and idoso_id = p_idoso;
$$;

-- celulares conectados + cuidadores (só para quem cuida)
create function public.pessoas_do_idoso(p_idoso uuid)
returns table (user_id uuid, papel text, aparelho text, ultimo_uso timestamptz, recebe_avisos boolean,
               nome text, sobrenome text, whatsapp text, autoriza_whatsapp boolean, sou_eu boolean)
language sql stable security definer set search_path = '' as $$
  select a.user_id, a.papel, a.aparelho, a.ultimo_uso, a.recebe_avisos,
         c.nome, c.sobrenome, c.whatsapp, coalesce(c.autoriza_whatsapp, false),
         a.user_id = (select auth.uid())
  from public.acessos a
  left join public.cuidadores c on c.user_id = a.user_id
  where a.idoso_id = p_idoso and public.pode_editar(p_idoso)
  order by a.papel desc, a.created_at;
$$;

-- Avisos / "Quem recebe"
create function public.definir_recebe_avisos(p_idoso uuid, p_user uuid, p_valor boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.pode_editar(p_idoso) then raise exception 'Sem permissão.'; end if;
  update public.acessos set recebe_avisos = p_valor
   where idoso_id = p_idoso and user_id = p_user and papel = 'cuidador';
end $$;

-- Horários das refeições: remédios que estavam no horário antigo do turno
-- passam para o novo horário
create function public.atualizar_refeicoes(p_idoso uuid, p_cafe time, p_almoco time, p_jantar time) returns void
language plpgsql security definer set search_path = '' as $$
declare v public.idosos;
begin
  if not public.pode_editar(p_idoso) then raise exception 'Sem permissão.'; end if;
  select * into v from public.idosos where id = p_idoso;
  update public.horarios h
     set hora = case h.turno when 'manha' then p_cafe when 'almoco' then p_almoco else p_jantar end
    from public.medicamentos m
   where m.id = h.medicamento_id and m.idoso_id = p_idoso
     and h.hora = case h.turno when 'manha' then v.hora_cafe when 'almoco' then v.hora_almoco else v.hora_jantar end;
  update public.idosos set hora_cafe = p_cafe, hora_almoco = p_almoco, hora_jantar = p_jantar
   where id = p_idoso;
end $$;

-- Privacidade / "Apagar todos os dados" (as fotos o app apaga antes, pela API do Storage)
create function public.apagar_idoso(p_idoso uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.pode_editar(p_idoso) then raise exception 'Sem permissão.'; end if;
  delete from public.idosos where id = p_idoso;
end $$;

-- permissões
revoke execute on function public.entrar_como_idoso(text, text), public.registrar_uso(uuid, text),
  public.pessoas_do_idoso(uuid), public.definir_recebe_avisos(uuid, uuid, boolean),
  public.atualizar_refeicoes(uuid, time, time, time), public.apagar_idoso(uuid),
  public.doses_de_hoje(uuid) from public, anon;
grant execute on function public.entrar_como_idoso(text, text), public.registrar_uso(uuid, text),
  public.pessoas_do_idoso(uuid), public.definir_recebe_avisos(uuid, uuid, boolean),
  public.atualizar_refeicoes(uuid, time, time, time), public.apagar_idoso(uuid),
  public.doses_de_hoje(uuid) to authenticated;
