CREATE OR REPLACE PROCEDURE SO_MON.SESSION_TRACKING_CLEANUP IS
T_SNAP_TIME	    DATE;

CURSOR ACTIVECUR IS select distinct(SNAP_TIME) from SO_MON.NUM_ACTIVE where SNAP_TIME < sysdate -90;
CURSOR DELIDLECUR IS select distinct(SNAP_TIME) from SO_MON.NUM_ACTIVE where SNAP_TIME < sysdate -1.5;

BEGIN
    OPEN DELIDLECUR;
    LOOP    
        FETCH DELIDLECUR INTO T_SNAP_TIME;
        EXIT WHEN (DELIDLECUR%NOTFOUND);
		DELETE FROM SO_MON.SESSION_TRACKING where SNAP_TIME = T_SNAP_TIME and STATUS = 'INACTIVE' and (INST_ID, SID) not in (SELECT nvl(BLOCKING_INSTANCE,0),nvl( BLOCKING_SESSION,0) from SO_MON.SESSION_TRACKING where SNAP_TIME = T_SNAP_TIME);
		COMMIT;
	COMMIT;
    END LOOP;
    CLOSE DELIDLECUR;


    OPEN ACTIVECUR;
    LOOP    
        FETCH ACTIVECUR INTO T_SNAP_TIME;
        EXIT WHEN (ACTIVECUR%NOTFOUND);
		DELETE FROM SO_MON.OPEN_CURSORS where SNAP_TIME = T_SNAP_TIME;
		DELETE FROM SO_MON.SESSION_TRACKING where SNAP_TIME = T_SNAP_TIME;
		DELETE FROM SO_MON.NUM_ACTIVE where SNAP_TIME = T_SNAP_TIME;
		DELETE FROM SO_MON.CUM_WAITS where SNAP_TIME = T_SNAP_TIME;
		DELETE FROM SO_MON.USER_COMMITS where SNAP_TIME = T_SNAP_TIME;
		DELETE FROM SO_MON.LONG_OPS where SNAP_TIME = T_SNAP_TIME;
	COMMIT;
    END LOOP;
    CLOSE ACTIVECUR;


COMMIT;
END;
/
