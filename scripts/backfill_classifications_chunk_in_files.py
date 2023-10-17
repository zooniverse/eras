import os
import psycopg
from datetime import datetime
import math

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

start_time = datetime.now()
print("CLASSIFICATIONS backfill BEFORE Time =", start_time)

classifications_query = "select id::bigint as classification_id, created_at as event_time, updated_at as classification_updated_at, CASE WHEN metadata ->> 'started_at' ~'\d{1,2}\/\d{1,2}\/\d{2,4}' THEN to_timestamp(metadata ->> 'started_at', 'MM/DD/YYYY HH24:MI') ELSE TO_TIMESTAMP(metadata ->> 'started_at', 'YYYY-MM-DD HH24:MI:SS') END started_at,  CASE WHEN metadata ->> 'finished_at' ~'\d{1,2}\/\d{1,2}\/\d{2,4}' THEN to_timestamp(metadata ->> 'finished_at', 'MM/DD/YYYY HH24:MI') ELSE TO_TIMESTAMP(metadata ->> 'finished_at', 'YYYY-MM-DD HH24:MI:SS') END finished_at, project_id::bigint, workflow_id::bigint, user_id::bigint, array_remove(string_to_array(replace(replace(replace(metadata ->> 'user_group_ids', '[', ''), ']', ''), ' ', '' ), ','), 'null')::bigint[] as user_group_ids, EXTRACT(EPOCH FROM (CASE WHEN metadata ->> 'finished_at' ~'\d{1,2}\/\d{1,2}\/\d{2,4}' THEN to_timestamp(metadata ->> 'finished_at', 'MM/DD/YYYY HH24:MI') ELSE TO_TIMESTAMP(metadata ->> 'finished_at', 'YYYY-MM-DD HH24:MI:SS') END) - (CASE WHEN metadata ->> 'started_at' ~'\d{1,2}\/\d{1,2}\/\d{2,4}' THEN to_timestamp(metadata ->> 'started_at', 'MM/DD/YYYY HH24:MI') ELSE TO_TIMESTAMP(metadata ->> 'started_at', 'YYYY-MM-DD HH24:MI:SS') END)) as session_time, created_at, updated_at from classifications where id < %s order by id desc"

offset = 0
limit = 10000000
num_files = math.ceil(FIRST_INGESTED_CLASSIFICATION_ID/limit)

while offset <= num_files:
  query = ''

  if offset == 0:
    query = f"{classifications_query} limit {limit}"
  else:
    query = f"{classifications_query} limit {limit} offset {limit * offset}"

  with psycopg.connect(f"host={PANOPTES_CONN} port={PANOPTES_PORT} dbname={PANOPTES_DB} user={PANOPTES_USER} password={PANOPTES_PW} sslmode=require") as panoptes_db_conn:
    with open(f"prod_classifications_{offset}.csv", "wb") as f:
        with panoptes_db_conn.cursor(name="panoptes_cursor").copy(f"COPY ({classifications_query}) TO STDOUT WITH CSV HEADER", (FIRST_INGESTED_CLASSIFICATION_ID,)) as panoptes_copy:
            for data in panoptes_copy:
                f.write(data)
    offset+= 1

finish_copy_time = datetime.now()
print("PANOPTES Classification Copy over at ", finish_copy_time)
print("TIMESCALE START COPY FROM CSV")

output_file_no = 0
while output_file_no <= num_files:
    with psycopg.connect(f"host={TIMESCALE_CONNECTION} port={TIMESCALE_PORT} dbname={ERAS_DB} user={ERAS_USER} password={ERAS_PW} sslmode=require") as timescale_db_conn:
        with timescale_db_conn.cursor(name="timescale_cursor").copy("COPY classification_events FROM STDIN DELIMITER ',' CSV HEADER") as timescale_copy:
            timescale_copy.write(open(f"prod_classifications_{output_file_no}.csv").read())
    output_file_no += 1

finish_time = datetime.now()
print("CLASSIFICATIONS TIMESCALE backfill AFTER Time =", finish_time)


