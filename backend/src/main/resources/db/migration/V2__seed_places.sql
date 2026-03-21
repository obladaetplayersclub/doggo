insert into place (
    id, created_at, updated_at, name, address, description, category, district, metro_station, latitude, longitude
)
select '8bb7466b-6535-4b13-9559-26d4753dd690', current_timestamp, current_timestamp, 'Doggo Vet Tverskaya', 'Москва, Тверская улица, 18к1', 'Клиника с терапией, вакцинацией и базовой диагностикой.', 'VET_CLINIC', 'Тверской', 'Тверская', 55.766807, 37.604407
where not exists (select 1 from place where id = '8bb7466b-6535-4b13-9559-26d4753dd690');

insert into place (
    id, created_at, updated_at, name, address, description, category, district, metro_station, latitude, longitude
)
select 'c34a2202-05c2-4ea8-b42c-a9364ccfdd27', current_timestamp, current_timestamp, 'Paws & Clean', 'Москва, Садовая-Кудринская улица, 25', 'Груминг-салон для собак средних и мелких пород.', 'GROOMING', 'Пресненский', 'Баррикадная', 55.760683, 37.584918
where not exists (select 1 from place where id = 'c34a2202-05c2-4ea8-b42c-a9364ccfdd27');

insert into place (
    id, created_at, updated_at, name, address, description, category, district, metro_station, latitude, longitude
)
select '5f7db76d-f731-4f3b-aa2d-860750ea3cdf', current_timestamp, current_timestamp, 'Площадка на Чистых прудах', 'Москва, Чистопрудный бульвар, 12А', 'Огороженная площадка для активного выгула и тренировки.', 'WALK_AREA', 'Басманный', 'Чистые пруды', 55.765858, 37.640384
where not exists (select 1 from place where id = '5f7db76d-f731-4f3b-aa2d-860750ea3cdf');

insert into place (
    id, created_at, updated_at, name, address, description, category, district, metro_station, latitude, longitude
)
select '5428ad57-02bb-4e10-b3fa-9d5fd9a80ae0', current_timestamp, current_timestamp, 'CityDog Market', 'Москва, Цветной бульвар, 21с7', 'Магазин с кормом, аммуницией и аксессуарами.', 'OTHER', 'Тверской', 'Цветной бульвар', 55.771052, 37.620654
where not exists (select 1 from place where id = '5428ad57-02bb-4e10-b3fa-9d5fd9a80ae0');

insert into place (
    id, created_at, updated_at, name, address, description, category, district, metro_station, latitude, longitude
)
select '2191b47c-63d6-4b90-8a5d-9ea4546d8779', current_timestamp, current_timestamp, 'VetLab South', 'Москва, Ленинский проспект, 45', 'Ветеринарный центр с лабораторией и хирургией.', 'VET_CLINIC', 'Гагаринский', 'Ленинский проспект', 55.693528, 37.561383
where not exists (select 1 from place where id = '2191b47c-63d6-4b90-8a5d-9ea4546d8779');

insert into place (
    id, created_at, updated_at, name, address, description, category, district, metro_station, latitude, longitude
)
select '06433fbf-fb25-4df0-91da-7f58b283ea34', current_timestamp, current_timestamp, 'North Groom Studio', 'Москва, Дмитровское шоссе, 72', 'Груминг, спа-уход и экспресс-мытье.', 'GROOMING', 'Тимирязевский', 'Верхние Лихоборы', 55.858977, 37.556873
where not exists (select 1 from place where id = '06433fbf-fb25-4df0-91da-7f58b283ea34');

insert into place (
    id, created_at, updated_at, name, address, description, category, district, metro_station, latitude, longitude
)
select '8c052271-40c9-4c0d-b33f-f6d5820a0bb3', current_timestamp, current_timestamp, 'Sokolniki Dog Park', 'Москва, парк Сокольники', 'Просторная зона выгула с инфраструктурой для тренировок.', 'WALK_AREA', 'Сокольники', 'Сокольники', 55.794229, 37.679090
where not exists (select 1 from place where id = '8c052271-40c9-4c0d-b33f-f6d5820a0bb3');

insert into place (
    id, created_at, updated_at, name, address, description, category, district, metro_station, latitude, longitude
)
select 'a9bde1dc-e6f6-49df-a36b-6b07774db001', current_timestamp, current_timestamp, 'Doggo Community Hub', 'Москва, Новослободская улица, 16', 'Клуб и коворкинг для dog-friendly встреч и консультаций.', 'OTHER', 'Тверской', 'Менделеевская', 55.781681, 37.598995
where not exists (select 1 from place where id = 'a9bde1dc-e6f6-49df-a36b-6b07774db001');
