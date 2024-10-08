##
## This script along with save_classifications_chunk_in_files.py was used in VM when first introducing ERAS.
## We needed to backfill classifications into ERAS db.
## The script was preluded with backfll_classifications.py which does a straight copy from panoptes db to copy to eras db.
## There was too much data to do a straight copy from panoptes db to copy to eras db, so we had to chunk in files. 
## See PR: https://github.com/zooniverse/eras/pull/40
##

import os
import psycopg
from datetime import datetime
import math

TIMESCALE_CONNECTION = os.getenv('TIMESCALE_CONNECTION')
TIMESCALE_PORT = os.getenv('TIMESCALE_PORT')
ERAS_DB = os.getenv('ERAS_DB')
ERAS_USER = os.getenv('ERAS_USER')
ERAS_PW = os.getenv('ERAS_PW')
FIRST_INGESTED_CLASSIFICATION_ID = os.getenv('FIRST_INGESTED_CLASSIFICATION_ID')

limit = 10000000
num_files = math.ceil(int(FIRST_INGESTED_CLASSIFICATION_ID)/limit)

start_time = datetime.now()
print("TIMESCALE START COPY FROM CSV BEFORE TIME =", start_time)

output_file_no = 0
while output_file_no <= num_files:
    with psycopg.connect(f"host={TIMESCALE_CONNECTION} port={TIMESCALE_PORT} dbname={ERAS_DB} user={ERAS_USER} password={ERAS_PW} sslmode=require keepalives=1 keepalives_idle=30 keepalives_interval=10 keepalives_count=20") as timescale_db_conn:
        with timescale_db_conn.cursor(name="timescale_cursor").copy("COPY classification_events FROM STDIN DELIMITER ',' CSV HEADER") as timescale_copy:
            timescale_copy.write(open(f"prod_classifications_{output_file_no}.csv").read())
    print("FINISHED COPYING FILE #", output_file_no)
    output_file_no += 1

finish_time = datetime.now()
print("CLASSIFICATIONS TIMESCALE backfill AFTER Time =", finish_time)