

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
CREATE OR REPLACE PROCEDURE public.populate_stg_purshase()
 LANGUAGE plpgsql
AS $procedure$
declare
fpurshasedate text;
		fuserid integer;
		fbilling integer;
		futmdate text;
		futmsource text;
		n integer;
		cash float;
		rowcount integer;
 curs_user_id cursor for 	select distinct userid, purshasedate from purchases p   ;
 curs_purshase cursor for select a.billing , a.purshasedate , b.utmdate , b.utmsource 
	from purchases a join user_utm b on a.userid=b.userid and b.utmdate < a.purshasedate and a.userid =fuserid and a.purshasedate=fpurshasedate
order by b.utmdate desc;  

begin
	truncate table public.stg_purchases;
	open curs_user_id;
loop
	fetch curs_user_id into fuserid,fpurshasedate;
	if not found then exit; end if; 
    n := 1;
   	rowcount:=(select count(*)  from purchases a join user_utm b on a.userid=b.userid and b.utmdate < a.purshasedate and a.userid =fuserid  and a.purshasedate=fpurshasedate);
	open curs_purshase;
   loop 
   		fetch curs_purshase into fbilling,fpurshasedate,futmdate,futmsource;
   		if not found then exit; end if; 
   if n=1 then cash:=fbilling*0.5;
   else cash :=fbilling*0.5/(ROWCOUNT-1);
   end if;
     insert into public.stg_purchases (userid, utmsource, purshasedate, cash, utmdate, row_num,rowcount,billing) 
  		 values(fuserid,futmsource,fpurshasedate,cash ,futmdate, n, rowcount,fbilling);
  		n:=n+1;
   end loop;
   	close curs_purshase;
   	
end loop;
    close curs_user_id; 


end;
$procedure$
;
call public.populate_stg_purshase();

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
from user_utm ;



---set registration count
update fact_purshases a
set number_of_registrations = count
from stg_registration b 
where a.calendaredate =b.utmdate and a.utmpsource =b.utmsource ;

---set purshase number
with purshase_cnt as (select count(*) cnt ,utmsource, cast(purshasedate as date) pdate
from stg_purchases 
where row_num =1
group by utmsource, cast(purshasedate as date))
update fact_purshases a
set number_of_purshases = b.cnt
from purshase_cnt b where a.calendareDate=b.pdate and a.utmpsource=b.utmsource ;

----set total billing 
with purshase_cnt as (select sum(cash) total_billing ,utmsource, cast(purshasedate as date) pdate
from stg_purchases
group by utmsource, cast(purshasedate as date))
update fact_purshases a
set total_billing = b.total_billing
from purshase_cnt b where a.calendareDate=b.pdate and a.utmpsource=b.utmsource ;


select * 
from fact_purshases
order by 1,2;





