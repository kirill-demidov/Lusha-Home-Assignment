

drop table if exists fact_purshases;
create table fact_purshases (
calendareDate date,
utmpSource varchar(100),
number_of_registrations int,
number_of_purshases int,
total_billing decimal(12,6)
)
--
--
--/*populate stg_registration*/
--
DROP TABLE public.stg_registration;

CREATE TABLE public.stg_registration (
	count int8 NULL,
	utmsource varchar(255) NULL,
	utmdate date NULL
);
with a as (select min(utmdate)utmdate,userid 
from user_utm uu 
group by userid )
insert  into stg_registration
select count(*) , uu.utmsource, cast(uu.utmdate  as date)
from user_utm uu join a on uu.utmdate =a.utmdate
group by uu.utmsource, cast(uu.utmdate  as date)


/*populate table stg_purchases*/

call public.populate_stg_purshase()

--/*getting number of purshases by date and utmsource*/
--select count(*), utmsource, cast(purshasedate as date)
--from stg_purchases sp 
--where row_num =1
--group by utmsource, cast(purshasedate as date)
--
--/*getting total_billing by date and utmsource*/
--select sum(cash),cast(purshasedate as date),utmsource 
--from stg_purchases sp 
--group by cast(purshasedate as date),utmsource 
--order by 2,1


/*populate fact_purshase table*/
truncate table fact_purshases;
insert into fact_purshases (calendaredate, utmpsource)
select distinct cast(utmdate as date) , utmsource
from user_utm 



---set registration count
update fact_purshases a
set number_of_registrations = count
from stg_registration b 
where a.calendaredate =b.utmdate and a.utmpsource =b.utmsource 

---set purshase number
with purshase_cnt as (select count(*) cnt ,utmsource, cast(purshasedate as date) pdate
from stg_purchases 
where row_num =1
group by utmsource, cast(purshasedate as date))
update fact_purshases a
set number_of_purshases = b.cnt
from purshase_cnt b where a.calendareDate=b.pdate and a.utmpsource=b.utmsource 

----set total billing 
with purshase_cnt as (select sum(cash) total_billing ,utmsource, cast(purshasedate as date) pdate
from stg_purchases
group by utmsource, cast(purshasedate as date))
update fact_purshases a
set total_billing = b.total_billing
from purshase_cnt b where a.calendareDate=b.pdate and a.utmpsource=b.utmsource 


select * 
from fact_purshases
order by 1,2





