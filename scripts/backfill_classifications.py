import os
import psycopg
from datetime import datetime

PANOPTES_CONN = os.getenv('PANOPTES_CONN')
PANOPTES_PORT = os.getenv('PANOPTES_PORT')
PANOPTES_DB = os.getenv('PANOPTES_DB')
PANOPTES_USER = os.getenv('PANOPTES_USER')
PANOPTES_PW = os.getenv('PANOPTES_PW')
TIMESCALE_CONNECTION = os.getenv('TIMESCALE_CONNECTION')
TIMESCALE_PORT = os.getenv('TIMESCALE_PORT')
ERAS_DB = os.getenv('ERAS_DB')
ERAS_USER = os.getenv('ERAS_USER')
ERAS_PW = os.getenv('ERAS_PW')
FIRST_INGESTED_CLASSIFICATION_ID = os.getenv('FIRST_INGESTED_CLASSIFICATION_ID')

now = datetime.now()
current_time = now.strftime("%H:%M:%S")
print("CLASSIFICATIONS backfill BEFORE Time =", current_time)

with psycopg.connect(f"host={PANOPTES_CONN} port={PANOPTES_PORT} dbname={PANOPTES_DB} user={PANOPTES_USER} password={PANOPTES_PW}") as panoptes_db_conn, psycopg.connect(f"host={TIMESCALE_CONNECTION} port={TIMESCALE_PORT} dbname={ERAS_DB} user={ERAS_USER} password={ERAS_PW}") as timescale_db_conn:
    with panoptes_db_conn.cursor(name="panoptes_cursor").copy(f"COPY (select id as classification_id, created_at as event_time, updated_at as classification_updated_at, TO_TIMESTAMP(metadata ->> 'started_at', 'YYYY-MM-DD HH24:MI:SS') as started_at, TO_TIMESTAMP(metadata ->> 'finished_at', 'YYYY-MM-DD HH24:MI:SS') as finished_at, project_id, workflow_id, user_id, string_to_array(replace(replace(replace(metadata ->> 'user_group_ids', '[', ''), ']', ''), ' ', '' ), ',')::int[] as user_group_ids, EXTRACT(EPOCH FROM TO_TIMESTAMP(metadata ->> 'finished_at', 'YYYY-MM-DD HH24:MI:SS') - TO_TIMESTAMP(metadata ->> 'started_at', 'YYYY-MM-DD HH24:MI:SS')) as session_time, created_at, updated_at from classifications where id < {FIRST_INGESTED_CLASSIFICATION_ID}) TO STDOUT (FORMAT BINARY)") as panoptes_copy:
        with timescale_db_conn.cursor().copy("COPY classification_events FROM STDIN (FORMAT BINARY)") as timescale_copy:
            for data in panoptes_copy:
                timescale_copy.write(data)

            finish = datetime.now()
            finish_time = finish.strftime("%H:%M:%S")
            print("CLASSIFICATIONS backfill AFTER Time =", finish_time)