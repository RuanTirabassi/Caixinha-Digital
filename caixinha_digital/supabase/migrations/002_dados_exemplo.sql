-- Dados de exemplo (persona Sra. Maria Judite). Já aplicado no projeto.
-- Código do idoso: 024587 | Código para cuidadores: 20262026
with i as (
  insert into public.idosos (nome, sobrenome, tratamento, whatsapp, codigo_acesso, codigo_cuidador)
  values ('Maria Judite', 'Ferreira', 'senhora', '43999999999', '024587', '20262026') returning id
), m as (
  insert into public.medicamentos (idoso_id, nome, dose_texto, finalidade, formato, cor)
  select i.id, v.nome, v.dose, v.fin, v.fmt, v.cor from i,
  (values ('Losartana','1 comprimido de 50mg','Para a pressão','redondo','Branco'),
          ('Metformina','1 comprimido de 850mg','Para o diabetes','oval','Branco'),
          ('Sinvastatina','1 comprimido de 20mg','Para o colesterol','redondo','Rosa')) v(nome,dose,fin,fmt,cor)
  returning id, nome
), h as (
  insert into public.horarios (medicamento_id, hora, turno)
  select m.id, case m.nome when 'Losartana' then '08:00'::time when 'Metformina' then '12:00' else '20:00' end,
         case m.nome when 'Losartana' then 'manha' when 'Metformina' then 'almoco' else 'noite' end
  from m returning id
)
insert into public.documentos (idoso_id, tipo, titulo, origem, data)
select i.id, v.tipo, v.titulo, v.origem, v.data::date from i,
(values ('receita','Receita do clínico geral','Clínico Geral','2026-10-02'),
        ('exame','Exame de sangue','Laboratório','2026-09-25')) v(tipo,titulo,origem,data);
