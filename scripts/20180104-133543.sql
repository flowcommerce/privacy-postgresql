create schema kinesis;
set search_path to kinesis;

CREATE OR REPLACE FUNCTION partition_n_days(v_table_name text, number_days integer) RETURNS void
LANGUAGE 'plpgsql'
AS $$
begin
  -- setup events table to be partitioned daily
  perform partman.create_parent(v_table_name, 'created_at', 'time', 'daily');
  update partman.part_config
     set retention = number_days || ' days',
         retention_keep_table = false,
         retention_keep_index = false
   where parent_table = v_table_name;
end;
$$;

CREATE OR REPLACE FUNCTION create_kinesis_tables(
  p_schema_name text,
  p_stream_name text
) RETURNS text
  LANGUAGE 'plpgsql'
  AS $$
declare
  v_events_table_name text;
  v_queue_table_name text;
begin
  v_events_table_name = p_schema_name || '.' || p_stream_name;

  -- prefix w/ q_ - we need a unique name w/ sufficient room for
  -- unique child partition tables
  v_queue_table_name = p_schema_name || '.q_' || p_stream_name;

  execute 'create schema if not exists ' || p_schema_name;

  -- drop events table if exists
  execute 'drop table if exists ' || v_events_table_name || ' cascade';
  execute 'drop table if exists ' || v_queue_table_name || ' cascade';

  -- delete any partition for the events table
  delete from partman.part_config where parent_table in (v_events_table_name, v_queue_table_name);

  -- create the events table
  execute 'create table ' || v_events_table_name ||
  '(id                    text primary key,
    json                  json not null,
    created_at            timestamptz not null default now(),
    arrived_at            timestamptz not null,
    timestamp             timestamptz not null,
    processed_at          timestamptz
  ) with (fillfactor=50, autovacuum_enabled=false, toast.autovacuum_enabled=false)';

   execute 'comment on table ' || v_events_table_name || ' is ''Stores events from the kinesis stream ' || p_stream_name || '''';

   -- create the events queue table
   execute 'create table ' || v_queue_table_name ||
   '(id                    text primary key,
     num_attempts          smallint default 0 not null check (num_attempts >= 0),
     next_attempt_at       timestamptz not null default now(),
     error                 text,
     created_at            timestamptz not null default now()
   ) with (fillfactor=80)';
   execute 'comment on table ' || v_queue_table_name || ' is ''Queues events pending processing from the kinesis stream ' || p_stream_name || '''';

   perform kinesis.partition_n_days(v_events_table_name, 3);
   perform kinesis.partition_n_days(v_queue_table_name, 3);

   return v_events_table_name || ', ' || v_queue_table_name;
end;
$$;


