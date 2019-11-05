-- Such elaborate steps are needed because
-- From: http://www.sqlite.org/faq.html:
--    (11) How do I add or delete columns from an existing table in SQLite.
--    SQLite has limited ALTER TABLE support that you can use to add a column to the end of a table or
--    to change the name of a table. If you want to make more complex changes in the structure of a
--    table, you will have to recreate the table. You can save existing data to a temporary table, drop
--    the old table, create the new table, then copy the data back in from the temporary table

DROP TABLE IF EXISTS foglamp.tasks_new;

CREATE TABLE foglamp.tasks_new (
             id           uuid                        NOT NULL,                               -- PK
             schedule_id  uuid,                                                               -- Link between schedule & task table
             schedule_name character varying(255),                                            -- Name of the task
             process_name character varying(255)      NOT NULL,                               -- Name of the task's process
             state        smallint                    NOT NULL,                               -- 1-Running, 2-Complete, 3-Cancelled, 4-Interrupted
             start_time   DATETIME DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),            -- The date and time the task started UTC
             end_time     DATETIME,                                                           -- The date and time the task ended
             reason       character varying(255),                                             -- The reason why the task ended
             pid          integer                     NOT NULL,                               -- Linux process id
             exit_code    integer,                                                            -- Process exit status code (negative means exited via signal)
  CONSTRAINT tasks_new_pkey PRIMARY KEY ( id ),
  CONSTRAINT tasks_new_fk1 FOREIGN KEY  ( process_name )
  REFERENCES scheduled_processes ( name ) MATCH SIMPLE
             ON UPDATE NO ACTION
             ON DELETE NO ACTION );

INSERT INTO foglamp.tasks_new (id, schedule_id, schedule_name, process_name, state, start_time, end_time, reason, pid, exit_code) SELECT id, "", schedule_name, process_name, state, start_time, end_time, reason, pid, exit_code FROM foglamp.tasks;
UPDATE foglamp.tasks_new SET schedule_id = (SELECT id FROM foglamp.schedules WHERE foglamp.tasks_new.schedule_name = foglamp.schedules.schedule_name AND foglamp.tasks_new.process_name = foglamp.schedules.process_name);
DROP TABLE IF EXISTS foglamp.tasks;

CREATE TABLE foglamp.tasks (
             id           uuid                        NOT NULL,                               -- PK
             schedule_id  uuid,                                                               -- Link between schedule & task table
             schedule_name character varying(255),                                            -- Name of the task
             process_name character varying(255)      NOT NULL,                               -- Name of the task's process
             state        smallint                    NOT NULL,                               -- 1-Running, 2-Complete, 3-Cancelled, 4-Interrupted
             start_time   DATETIME DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),            -- The date and time the task started UTC
             end_time     DATETIME,                                                           -- The date and time the task ended
             reason       character varying(255),                                             -- The reason why the task ended
             pid          integer                     NOT NULL,                               -- Linux process id
             exit_code    integer,                                                            -- Process exit status code (negative means exited via signal)
  CONSTRAINT tasks_pkey PRIMARY KEY ( id ),
  CONSTRAINT tasks_fk1 FOREIGN KEY  ( process_name )
  REFERENCES scheduled_processes ( name ) MATCH SIMPLE
             ON UPDATE NO ACTION
             ON DELETE NO ACTION );

INSERT INTO foglamp.tasks SELECT id, schedule_id, schedule_name, process_name, state, start_time, end_time, reason, pid, exit_code FROM foglamp.tasks_new;
DROP TABLE IF EXISTS foglamp.tasks_new;

DROP INDEX IF EXISTS tasks_ix1;
CREATE INDEX tasks_ix1
    ON tasks(schedule_name, start_time);