create table if not exists app_user (
    id uuid primary key,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    email varchar(320) not null unique,
    password_hash varchar(255) not null,
    display_name varchar(120) not null,
    avatar_url varchar(512),
    role varchar(20) not null
);

create table if not exists pet (
    id uuid primary key,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    owner_id uuid not null references app_user(id) on delete cascade,
    name varchar(120) not null,
    breed varchar(120),
    birth_date date,
    gender varchar(20) not null,
    photo_url varchar(512),
    notes varchar(2000)
);

create index if not exists idx_pet_owner on pet(owner_id);

create table if not exists pet_allergy (
    id uuid primary key,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    pet_id uuid not null references pet(id) on delete cascade,
    name varchar(255) not null
);

create index if not exists idx_pet_allergy_pet on pet_allergy(pet_id);

create table if not exists pet_vaccination (
    id uuid primary key,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    pet_id uuid not null references pet(id) on delete cascade,
    name varchar(255) not null,
    vaccination_date date not null,
    comment varchar(1000)
);

create index if not exists idx_pet_vaccination_pet on pet_vaccination(pet_id);

create table if not exists pet_attachment (
    id uuid primary key,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    pet_id uuid not null references pet(id) on delete cascade,
    original_filename varchar(255) not null,
    storage_key varchar(255) not null,
    content_type varchar(255) not null,
    size_bytes bigint not null
);

create index if not exists idx_pet_attachment_pet on pet_attachment(pet_id);

create table if not exists reminder (
    id uuid primary key,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    owner_id uuid not null references app_user(id) on delete cascade,
    pet_id uuid not null references pet(id) on delete cascade,
    type varchar(20) not null,
    title varchar(255) not null,
    scheduled_at timestamp with time zone not null,
    next_trigger_at timestamp with time zone,
    last_triggered_at timestamp with time zone,
    recurrence varchar(20) not null,
    status varchar(20) not null,
    comment varchar(1000),
    completed_at timestamp with time zone
);

create index if not exists idx_reminder_owner on reminder(owner_id);
create index if not exists idx_reminder_pet on reminder(pet_id);
create index if not exists idx_reminder_trigger on reminder(status, next_trigger_at);

create table if not exists place (
    id uuid primary key,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    name varchar(255) not null,
    address varchar(512) not null,
    description varchar(1000),
    category varchar(30) not null,
    district varchar(120),
    metro_station varchar(120),
    latitude double precision not null,
    longitude double precision not null
);

create index if not exists idx_place_category on place(category);
create index if not exists idx_place_district on place(district);
create index if not exists idx_place_metro on place(metro_station);

create table if not exists review (
    id uuid primary key,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    place_id uuid not null references place(id) on delete cascade,
    author_id uuid not null references app_user(id) on delete cascade,
    rating integer not null,
    text varchar(1000) not null,
    status varchar(30) not null,
    complaint_count integer not null default 0,
    constraint uq_review_place_author unique (place_id, author_id)
);

create index if not exists idx_review_place_status on review(place_id, status);
create index if not exists idx_review_author_created on review(author_id, created_at);

create table if not exists review_complaint (
    id uuid primary key,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    review_id uuid not null references review(id) on delete cascade,
    reporter_id uuid not null references app_user(id) on delete cascade,
    reason varchar(500) not null,
    constraint uq_review_reporter unique (review_id, reporter_id)
);

create index if not exists idx_review_complaint_review on review_complaint(review_id);

create table if not exists walk (
    id uuid primary key,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    owner_id uuid not null references app_user(id) on delete cascade,
    pet_id uuid not null references pet(id) on delete cascade,
    started_at timestamp with time zone not null,
    ended_at timestamp with time zone,
    distance_meters double precision not null,
    status varchar(20) not null
);

create index if not exists idx_walk_owner_pet on walk(owner_id, pet_id, started_at desc);
create index if not exists idx_walk_pet_status on walk(pet_id, status);

create table if not exists walk_point (
    id uuid primary key,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    walk_id uuid not null references walk(id) on delete cascade,
    latitude double precision not null,
    longitude double precision not null,
    recorded_at timestamp with time zone not null
);

create index if not exists idx_walk_point_walk on walk_point(walk_id, recorded_at);
