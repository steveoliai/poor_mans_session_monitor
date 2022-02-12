create table SO_MON.MONUSERS (DBUSERNAME varchar(20));

create table SO_MON.SERIALNUM (SERIAL_NUM number);

insert into SO_MON.MONUSERS values ('CDSWEB');
insert into SO_MON.MONUSERS values ('SERVICE');
insert into SO_MON.SERIALNUM values (0);
COMMIT;


create table SO_MON.session_tracking as
select 0 as serial_num, sysdate as snap_time, s.status, s.inst_id, s.sid, s.serial#,  s.last_call_et/60 as last_call, q.executions, q.elapsed_time, s.username,  s.machine, s.program, s.state, s.event, s.sql_id, s.prev_sql_id, s.row_wait_obj#, s.row_wait_file#, s.row_wait_block#,s.row_wait_row#, s.blocking_instance, s.blocking_session, s.blocking_session_status, s.wait_time, s.seconds_in_wait,  q.sql_text, q.sql_fulltext from gv$session s join gv$sql q on s.sql_id = q.sql_id and s.inst_id = q.inst_id
where  s.username in ('XXXXXXXXXX');

create table so_mon.open_cursors as
select 0 as serial_num, sysdate as snap_time, inst_id, sid, user_name, sql_id, sql_text, last_sql_active_time, cursor_type from GV$OPEN_CURSOR where (inst_id, sid) in (select inst_id, sid from gv$session where user_name
in ('XXXXXXXXXX'));

create table SO_MON.NUM_ACTIVE (SERIAL_NUM number, SNAP_TIME date, NUM_ACTIVE number);

create table SO_MON.CUM_WAITS as select 0 as serial_num, sysdate as snap_time, WAIT_CLASS, EVENT, sum(TIME_WAITED) as sum_time_waited, sum(TIME_WAITED)/sum(TOTAL_WAITS) Avg_Waits 
from   GV$SESSION_EVENT
group by WAIT_CLASS, EVENT Order by 3 desc;

create table SO_MON.USER_COMMITS as select 0 as serial_num, sysdate as snap_time, sum(value) as sum_value from gv$sysstat where name='user commits';

create table SO_MON.LONG_OPS as 
SELECT 0 as serial_num, sysdate as snap_time, l.inst_id, l.sid, to_char(start_time,'hh24:mi:ss') stime, l.opname,
message,( sofar/totalwork)* 100 percent, l.sql_id, s.sql_text, s.sql_fulltext, s.executions, s.elapsed_time 
FROM gv$session_longops l,  gv$sql s where l.inst_id = s.inst_id and l.sql_id = s.sql_id
and sofar/totalwork < 1 and nvl(totalwork,0) <> 0 ;

CREATE INDEX SO_MON.SESSION_TRACKING_1 ON SO_MON.SESSION_TRACKING
(SNAP_TIME)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.SESSION_TRACKING_2 ON SO_MON.SESSION_TRACKING
(SID)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.SESSION_TRACKING_3 ON SO_MON.SESSION_TRACKING
(SERIAL_NUM)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.OPEN_CURSORS_1 ON SO_MON. OPEN_CURSORS 
(SNAP_TIME)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.OPEN_CURSORS_2 ON SO_MON.OPEN_CURSORS
(SID)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.OPEN_CURSORS_3 ON SO_MON.OPEN_CURSORS
(SERIAL_NUM)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.NUM_ACTIVE_1 ON SO_MON.NUM_ACTIVE
(SERIAL_NUM)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.NUM_ACTIVE_2 ON SO_MON.NUM_ACTIVE
(SNAP_TIME)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.CUM_WAITS_1 ON SO_MON.CUM_WAITS
(SERIAL_NUM)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.CUM_WAITS_2 ON SO_MON.CUM_WAITS
(SNAP_TIME)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.USER_COMMITS_1 ON SO_MON.USER_COMMITS
(SERIAL_NUM)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.USER_COMMITS_2 ON SO_MON.USER_COMMITS
(SNAP_TIME)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.LONG_OPS_1 ON SO_MON.LONG_OPS
(SNAP_TIME)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.LONG_OPS_2 ON SO_MON.LONG_OPS
(SID)
LOGGING
NOPARALLEL;

CREATE INDEX SO_MON.LONG_OPS_3 ON SO_MON.LONG_OPS
(SERIAL_NUM)
LOGGING
NOPARALLEL;