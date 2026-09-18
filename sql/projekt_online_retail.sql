/* PROJEKT: Analiza sprzedaży e-commerce — Online Retail II
   
   Baza:PostgreSQL 18 (Postgres.app) + pgAdmin 4
   Dane:Online Retail II (UCI) — ~1,07 mln transakcji brytyjskiego sklepu internetowego, okres 2009-12-01 do 2011-12-09.
   Źródło:Daqing Chen, UCI Machine Learning Repository
   Licencja: Creative Commons Attribution 4.0 (CC BY 4.0)
   Zakres:ładowanie danych, czyszczenie, analizy podstawowe,segmentacja RFM, funkcje okna, łączenie tabel (JOIN).
 
   Jak używać: uruchamiaj sekcjami, od góry do dołu. Sekcje 1–2 tworzą
                tabele i widoki, na których opierają się kolejne zapytania. */

/*Część 1 - ładowanie danych*/
	
/*Tworzenie surowej tabeli*/

create table retail_raw (
    invoice      text,
    stock_code   text,
    description  text,
    quantity     text,
    invoice_date text,
    price        text,
    customer_id  text,
    country      text
);

/*Sprawdzenie ilości wierszy tabeli*/
select count(*) from retail_raw;

/* Import pliku online_retail_II.csv do retail_raw. W pgAdmin: prawy przycisk na tabeli retail_raw -> Import/Export Data...
Import = ON, Format = csv, Encoding = UTF8, Header = ON, Delimiter = ',', Quote = '"'*/

/*Tworzenie tabeli na bazie schematu z poprzedniej tabeli*/
create table retail as
select
    invoice,
    stock_code,
    description,
    quantity::integer                        as quantity,
    invoice_date::timestamp                   as invoice_date,
    price::numeric(10,2)                       as price,
    nullif(customer_id, '')::numeric::integer as customer_id,
    country
from retail_raw;

/*Wyświetlenie 10 pierwszych wierszy tabeli*/
select * from retail limit 10;

/*Część 2 - eksploracja i czyszczenie danych*/

/*Sprawdzenie zakresu dat w tabeli*/
select
    min(invoice_date) as pierwsza_transakcja,
    max(invoice_date) as ostatnia_transakcja
from retail;

/*Wyliczenie, ile jest braków danych w kolumnie customer_id*/
select count(*) as bez_id
from retail
where customer_id is null;

/* Wyliczenie, ile jest anulowanych produktów */
selec count (*) as anulowania
from retail
where invoice like 'C%';

/*Wyliczenie, ile jest zwrotów*/
select count(*) as ujemne_ilosci
from retail
where quantity < 0;

/*Wyświetlenie podstawowych danych o zbiorze*/
select
    count(*)                                   as wszystkie_wiersze,
    count(customer_id)                         as z_id_klienta,
    count(*) - count(customer_id)              as bez_id_klienta,
    count(distinct invoice)                     as unikalne_faktury,
    count(distinct customer_id)                 as unikalni_klienci,
    count(distinct country)                     as liczba_krajow
from retail;

/*Rworzenie widoku sprzedaży brutto, bez zaktualizowania, które z nich zostały anulowane*/
create view sprzedaz as
select *
from retail
where invoice not like 'C%'   
  and quantity > 0           
  and price > 0;              

/* Stworzenie view z dodatkową kolumna "wartosc" dla kazdego produktu*/
create or replace view transakcje as
select *,
       quantity * price as wartosc   /* ujemna dla zwrotów, dodatnia dla sprzedaży*/
from retail
where price <> 0; 

select * from transakcje;

/*Część 3 - podtawowe analizy*/

/*Sprawdzenie, jakie produkty sie najlepiej sie sprzedają*/
create materialized view top_produkty as
select 
	stock_code,
	max(description) as przyklad_nazwy,
	sum(quantity) as sztuk_sprzedanych
from sprzedaz
group by stock_code
order by sztuk_sprzedanych desc
limit 10;

select * from top_produkty limit 10;

/*Sprawdzenie, jakie produkty przynoszą największy obrót*/
SELECT
    stock_code,
    MAX(description)                AS przyklad_nazwy,
    ROUND(SUM(quantity * price), 2) AS przychod
FROM sprzedaz
GROUP BY stock_code
ORDER BY przychod DESC
LIMIT 10;

/*Sprawdzanie, który kraj ma najwiekszy obrót*/
create materialized view top_kraje as
select
	country,
	round(sum(quantity*price),2) as obrot,
	count(distinct invoice) as liczba_faktur
from sprzedaz
group by country
order by obrot desc
limit 7;

select * from top_kraje limit 10;


/* Sprawdzanie, które miesiące przynoszą najlepszy obrót*/
create materialized view top_miesiace as
select
	date_trunc('month', invoice_date)::date as miesiac,
	round(sum(quantity*price), 2) as obrot
from sprzedaz
group by miesiac
order by miesiac;

select * from top_miesiace;

/* Sprawdzanie, jakie są maksymalne i minimalne wartości na fakturze*/
create materialized view min_max_wartosc_faktury as
select
    round(avg(wartosc_faktury), 2) as srednia_wartosc,
    round(min(wartosc_faktury), 2) as min_wartosc,
    round(max(wartosc_faktury), 2) as max_wartosc
from (
    select invoice, sum(quantity * price) as wartosc_faktury
    from sprzedaz
    group by invoice
) as faktury;

/* Sprawdzanie, którzy klienci wydają najwiecej*/
create materialized view top_klienci as
select
    customer_id,
    round(sum(quantity * price), 2) as obrot,
    count(distinct invoice)         as liczba_faktur
from sprzedaz
where customer_id is not null
group by customer_id
order by obrot desc
limit 10;

/*Sprawdzenie, w jakie dni klienci najczesciej kupują*/
create materialized view top_dni_tygodnia as
select
    to_char(invoice_date, 'Day')     as dzien,
    extract(dow from invoice_date)   as nr_dnia,
    count(distinct invoice)          as liczba_faktur,
    round(sum(quantity * price), 2)  as obrot
from sprzedaz
group by dzien, nr_dnia
order by nr_dnia;

select * from top_dni_tygodnia;

/*Sprawdzenie, który produkt najczęściej się sprzedaje*/
create materialized view top_produkty as
select
    stock_code,
    max(description) as przyklad_nazwy,
    sum(quantity)    as sztuk_sprzedanych
from sprzedaz
group by stock_code
order by sztuk_sprzedanych desc
limit 10;

select * from top_produkty limit 10;

/*Sprawdzenie, który produky maja najlepszy przychod*/
create materialized view top_przychody_produkty as
select
    stock_code,
    max(description)                as przyklad_nazwy,
    round(sum(quantity * price), 2) as przychod
from sprzedaz
group by stock_code
order by przychod desc
limit 10;

select * from top_przychody_produkty limit 10;

/*Sprawdzenie, ile jest faktur per godzina i jaki jest wtedy obrót*/
create materialized view faktury_przychod_per_godzina as
select
    extract(hour from invoice_date) as godzina,
    count(distinct invoice)         as liczba_faktur,
    found(sum(quantity * price), 2) as obrot
from sprzedaz
group by godzina
order by godzina;

/*Sprawdzenie, jakie produkty najczęściej sie zwraca*/
create materialized view produkty_per_zwroty as
select
    stock_code,
    max(description)    as przyklad_nazwy,
    sum(abs(quantity))  as sztuk_zwroconych
from retail
where invoice like 'C%'
  and quantity < 0
group by stock_code
order by sztuk_zwroconych desc
limit 10;

select * from produkty_per_zwroty limit 10;

/*Sprawdzenie sprawdzenie średniej i mediany wysokości faktury*/
select
    ROUND(avg(wartosc_faktury), 2) AS srednia,
    ROUND(
        percentile_cont(0.5) within group (order by wartosc_faktury)::numeric,
        2
    ) as mediana
from (
    select invoice, sum(quantity * price) as wartosc_faktury
    as sprzedaz
    group by invoice
) as faktury

/*Część 4 - segmentacja klientów oraz wgląd do segmentów*/

/* rfm */
create materialized view rfm as
with rfm AS (
    select
        customer_id,
        (date '2011-12-10' - max(invoice_date)::date) as recency_dni,
        count(distinct invoice)                        as frequency,
        ROUND(sum(quantity * price), 2)                as monetary
    from sprzedaz
    where customer_id is not null
    group by customer_id
),
scored AS (
    select customer_id, monetary,
        ntile(4) over (order by recency_dni desc) as r,
        ntile(4) over (order by frequency asc)    as f
    from rfm
),
segmenty as (
    select *,
        CASE
            when r >= 4 and f >= 4 then 'Champions'
            when r >= 3 and f >= 3 then 'Lojalni'
            when r >= 4 and f <= 2 then 'Nowi'
            when r >= 3 and f <= 2 then 'Obiecujący'
            when r <= 2 and f >= 3 then 'Zagrożeni'
            when r <= 2 and f <= 2 then 'Uśpieni'
            else 'Inni'
        end as segment
    from scored
)
select
    segment,
    count(*)                    as liczba_klientow,
    ROUND(sum(monetary))        as laczny_obrot
from segmenty
group by segment
order by laczny_obrot desc;

select * from rfm1;

/* Przychod per kraj*/
with produkty_kraj as (
	select
		country,
		stock_code,
		max(description) as nazwa,
		round(sum(quantity*price),2) as przychod
	from sprzedaz
	where stock_code ~ '^[0-9]{5}[A-Za-z]{0,2}$' 
	group by country, stock_code
),
rankingi as (
	select
	country, nazwa, przychod,
	rank() over (partition by country order by przychod desc) as pozycja
	from produkty_kraj
)	
select country,nazwa, przychod, pozycja
from rankingi
where pozycja = 1
order by przychod desc
limit 10;

select * from produkty_kraj;

/* Przychod miesiącami*/
with miesiace as (
	select 
		date_trunc('month', invoice_date):: date as miesiac,
		sum(quantity*price) as obrot
	from sprzedaz
	group by miesiac
)
select
	miesiac,
	round(obrot) as obrot,
	round(lag(obrot) over (order by miesiac)) as obrot_poprzedni,
	round(
		(obrot - lag(obrot) over (order by miesiac))
		/ lag(obrot) over (order by miesiac)* 100
	, 1) as zmiana_proc
from miesiace
order by miesiac;

/* Przychod miesiącami narastająco*/
with miesiace as (
	select
		date_trunc('month', invoice_date)::date as miesiac,
		sum(quantity*price) as obrot
	from sprzedaz
	group by miesiac	
)
select
	miesiac,
	round(obrot) as obrot_miesiaca,
	round(sum(obrot) over (order by miesiac)) as narastajace
from miesiace
order by miesiac;

/* Łączenie tabel*/
create table kod_kraj (country text primary key, region text, kontynent text);
insert into kod_kraj (country, region, kontynent) values
    ('United Kingdom','Wielka Brytania','Europa'),
    ('EIRE','Europa Zachodnia','Europa'),
    ('Netherlands','Europa Zachodnia','Europa'),
    ('Germany','Europa Zachodnia','Europa'),
    ('France','Europa Zachodnia','Europa'),
    ('Belgium','Europa Zachodnia','Europa'),
    ('Switzerland','Europa Zachodnia','Europa'),
    ('Austria','Europa Zachodnia','Europa'),
    ('Spain','Europa Poludniowa','Europa'),
    ('Portugal','Europa Poludniowa','Europa'),
    ('Italy','Europa Poludniowa','Europa'),
    ('Greece','Europa Poludniowa','Europa'),
    ('Malta','Europa Poludniowa','Europa'),
    ('Cyprus','Europa Poludniowa','Europa'),
    ('Sweden','Europa Polnocna','Europa'),
    ('Denmark','Europa Polnocna','Europa'),
    ('Norway','Europa Polnocna','Europa'),
    ('Finland','Europa Polnocna','Europa'),
    ('Iceland','Europa Polnocna','Europa'),
    ('Poland','Europa Srodkowa','Europa'),
    ('Lithuania','Europa Srodkowa','Europa'),
    ('Czech Republic','Europa Srodkowa','Europa'),
    ('Channel Islands','Europa Zachodnia','Europa'),
    ('Australia','Oceania','Oceania'),
    ('Japan','Azja','Azja'),
    ('Singapore','Azja','Azja'),
    ('Hong Kong','Azja','Azja'),
    ('Israel','Azja','Azja'),
    ('United Arab Emirates','Azja','Azja'),
    ('Bahrain','Azja','Azja'),
    ('Thailand','Azja','Azja'),
    ('Lebanon','Azja','Azja'),
    ('Korea','Azja','Azja'),
    ('Saudi Arabia','Azja','Azja'),
    ('USA','Ameryka Polnocna','Ameryka'),
    ('Canada','Ameryka Polnocna','Ameryka'),
    ('Bermuda','Ameryka Polnocna','Ameryka'),
    ('Brazil','Ameryka Poludniowa','Ameryka'),
    ('West Indies','Ameryka Poludniowa','Ameryka'),
    ('RSA','Afryka','Afryka'),
    ('Nigeria','Afryka','Afryka');

select * from kod_kraj;

select
	kr.kontynent,
	count(distinct s.invoice) as liczba_faktur,
	round(sum(s.quantity * s.price)) as obrot
from sprzedaz as s
inner join kod_kraj as kr
	on s.country = kr.country
group by kr.country
order by obrot desc;

select distinct
	s.country,
	kr.kontynent
from sprzedaz as s
left join kod_kraj as kr
	on s.country = kr.country
where kr.kontynent is null;

select
	kr.kontynent,
	round(sum(s.quantity *s.price)) as obrot,
	round(sum(s.quantity * s.price)::numeric/sum(sum(s.quantity*s.price)) over()*100
	, 1) as udzial_proc
from sprzedaz as s
inner join kod_kraj as kr on s.country = kr.country
group by kr.kontynent
order by obrot desc;