create table lock_log(
EVENT_TIME             TIMESTAMP(6),
BLOCKING_SESSION       NUMBER,
BLOCKING_SERIAL        NUMBER,
INST_ID                NUMBER,
USERNAME               VARCHAR2(30),
OSUSER                 VARCHAR2(30),
BLOCKED_SESSION        NUMBER,
SQL_ID                 VARCHAR2(13),
LOCK_TYPE              VARCHAR2(20),
LOCK_ID1               NUMBER,       
LOCK_ID2               NUMBER 
);

create or replace NONEDITIONABLE PROCEDURE check_locks AS
    num_locks NUMBER;
BEGIN
    -- Verifica o número de locks
    SELECT COUNT(*)
    INTO num_locks
    FROM v$lock
    WHERE request > 0; -- Locks solicitados (bloqueados)

    -- Se houver locks, registrar na tabela de log
    IF num_locks > 0 THEN
        FOR rec IN (
            SELECT
                l1.sid AS blocking_session,
                l2.sid AS blocked_session,
                l1.type AS lock_type,
                l1.id1 AS lock_id1,
                l1.id2 AS lock_id2,
                s1.username AS blocking_user,
                s1.osuser AS blocking_osuser,
                s2.username AS blocked_user,
                s1.serial# AS blocking_serial#,
                s1.sql_id AS blocking_sql_id
            FROM
                v$lock l1
                JOIN v$session s1 ON l1.sid = s1.sid
                JOIN v$lock l2 ON l1.id1 = l2.id1 AND l1.id2 = l2.id2
                JOIN v$session s2 ON l2.sid = s2.sid
            WHERE
                l1.block = 1 AND l2.request > 0
        ) LOOP
            INSERT INTO system.lock_log (
                event_time,
                blocking_session,
                blocking_serial,
                blocked_session,
                username,
                osuser,
                sql_id,
                inst_id,
                lock_type,
                lock_id1,
                lock_id2
            ) VALUES (
                SYSTIMESTAMP,
                rec.blocking_session,
                rec.blocking_serial#,
                rec.blocked_session,
                rec.blocking_user,
                rec.blocking_osuser,
                rec.blocking_sql_id,
                SYS_CONTEXT('USERENV', 'INSTANCE'),
                rec.lock_type,
                rec.lock_id1,
                rec.lock_id2
            );

            -- Kill the blocking session if it's a user session and not a background session
            IF rec.blocking_user IS NOT NULL THEN
                BEGIN
                    EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION ''' || rec.blocking_session || ',' || rec.blocking_serial# || ',@' || SYS_CONTEXT('USERENV', 'INSTANCE') || ''' IMMEDIATE';
                EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('Error killing session: ' || rec.blocking_session || ',' || rec.blocking_serial# || ',@' || SYS_CONTEXT('USERENV', 'INSTANCE') || ' - ' || SQLERRM);
                END;
            END IF;
        END LOOP;
        COMMIT;
    END IF;
END;
