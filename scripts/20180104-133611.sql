create schema if not exists organization;

drop table if exists organization.organizations;

set search_path to organization;

create table organizations (
  id                          text primary key check(util.non_empty_trimmed_string(id)),
  name                        text not null check(util.non_empty_trimmed_string(name)),
  environment                 text not null check(util.non_empty_trimmed_string(environment)),
  default_base_currency       text not null check(util.currency_code(default_base_currency)),
  default_country             text not null check(util.country_code(default_country)),
  default_language            text not null check(util.language_code(default_language)),
  default_locale              text not null check(util.non_empty_trimmed_string(default_locale)),
  default_timezone            text not null check(util.non_empty_trimmed_string(default_timezone)),
  parent_id                   text check(util.null_or_non_empty_trimmed_string(parent_id)),
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now(),
  updated_by_user_id          text not null check(util.non_empty_trimmed_string(updated_by_user_id)),
  hash_code                   bigint not null
);

select schema_evolution_manager.create_updated_at_trigger('organization', 'organizations');