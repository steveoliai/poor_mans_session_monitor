CREATE OR REPLACE PROCEDURE SO_MON.SESSION_TRACKING_INSERT IS
T_SNAP_TIME        DATE;
T_SERIAL_NUM        NUMBER;
T_CHECK         NUMBER;
T_CHECK2         NUMBER;
T_CHECK3         NUMBER;
BEGIN

T_SNAP_TIME := sysdate;

UPDATE SO_MON.SERIALNUM SET SERIAL_NUM = SERIAL_NUM+1;
SELECT SERIAL_NUM INTO T_SERIAL_NUM FROM SO_MON.SERIALNUM;
COMMIT;

insert into SO_MON.session_tracking
select T_SERIAL_NUM, T_SNAP_TIME, s.status, s.inst_id, s.sid, s.serial#,  s.last_call_et/60 as last_call, q.executions, q.elapsed_time, s.username,  s.machine, s.program, s.state, s.event, s.sql_id, s.prev_sql_id, s.row_wait_obj#, s.row_wait_file#, s.row_wait_block#,s.row_wait_row#, s.blocking_instance, s.blocking_session, s.blocking_session_status,  s.wait_time, s.seconds_in_wait, q.sql_text, q.sql_fulltext 
from gv$session s left outer join gv$sql q on s.sql_id = q.sql_id and s.inst_id = q.inst_id
where  s.username is not null and s.username <> 'SO_MON';

select count(*) into T_CHECK from (select distinct(inst_id), sid from SO_MON.session_tracking where SERIAL_NUM = T_SERIAL_NUM and STATUS = 'ACTIVE');

insert into so_mon.num_active values (T_SERIAL_NUM, T_SNAP_TIME, T_CHECK);
commit;
if T_CHECK  > 0 then
	select count(*) into T_CHECK2 from SO_MON.session_tracking where (inst_id, sid) in (select blocking_instance, blocking_session from SO_MON.session_tracking 
	where SNAP_TIME = T_SNAP_TIME and STATUS = 'ACTIVE') and SNAP_TIME = T_SNAP_TIME;

	if T_CHECK2>0 then
	    insert into so_mon.open_cursors 
	    select T_SERIAL_NUM, T_SNAP_TIME, inst_id, sid, user_name, sql_id, sql_text, last_sql_active_time, cursor_type from GV$OPEN_CURSOR where (inst_id, sid) in (select blocking_instance, blocking_session from SO_MON.session_tracking 
	    where SNAP_TIME = T_SNAP_TIME and STATUS = 'ACTIVE');
	end if;
	commit;	
	

end if;

select count(*) into T_CHECK3 from gv$session_longops l,  gv$sql s where l.inst_id = s.inst_id and l.sql_id = s.sql_id
and sofar/totalwork < 1 and nvl(totalwork,0) <> 0;

if T_CHECK3 > 0 then
	insert into SO_MON.LONG_OPS
	SELECT T_SERIAL_NUM, T_SNAP_TIME, l.inst_id, l.sid, to_char(start_time,'hh24:mi:ss') stime, l.opname, message,( sofar/totalwork)* 100 percent, l.sql_id, s.sql_text, s.sql_fulltext, s.executions, s.elapsed_time FROM gv$session_longops l,  gv$sql s where l.inst_id = s.inst_id and l.sql_id = s.sql_id and sofar/totalwork < 1 and nvl(totalwork,0) <> 0;
end if;
commit;

if MOD(T_SERIAL_NUM, 6) = 0 then
    insert into SO_MON.CUM_WAITS select T_SERIAL_NUM, T_SNAP_TIME, WAIT_CLASS, EVENT, sum(TIME_WAITED), sum(TIME_WAITED)/sum(TOTAL_WAITS) Avg_Waits 
    from   GV$SESSION_EVENT
    group by WAIT_CLASS, EVENT Order by 3 desc;
end if;
insert into SO_MON.USER_COMMITS (SERIAL_NUM, SNAP_TIME, SUM_VALUE) select T_SERIAL_NUM, T_SNAP_TIME, sum(value) from gv$sysstat where name='user commits' ;


commit;

--cleanup dups created by Oracles cache

delete from so_mon.session_tracking where (serial_num, inst_id, sid, executions) in (select s1.serial_num, s1.inst_id, s1.sid, s1.executions from so_mon.session_tracking s1, so_mon.session_tracking s2 where s1.serial_num = s2.serial_num and s1.inst_id = s2.inst_id and s1.sid = s2.sid and s1.executions < s2.executions and s1.serial_num = T_SERIAL_NUM );


COMMIT;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN NULL;

COMMIT;
END;
/

