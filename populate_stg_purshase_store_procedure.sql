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
   	
end loop; -- ??????????? ???? ?? ???????
    close curs_user_id; -- ????????? ??????


end;
$procedure$
;
