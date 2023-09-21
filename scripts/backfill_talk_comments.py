import os
import psycopg

TALK_CONN = os.getenv('TALK_CONNECTION')
TALK_PORT = os.getenv('TALK_PORT')
TALK_DB = os.getenv('TALK_DB')
TALK_USER = os.getenv('TALK_USER')
TALK_PW = os.getenv('TALK_PW')
TIMESCALE_CONNECTION = os.getenv('TIMESCALE_CONNECTION')
TIMESCALE_PORT = os.getenv('TIMESCALE_PORT')
ERAS_DB = os.getenv('ERAS_DB')
ERAS_USER = os.getenv('ERAS_USER')
ERAS_PW = os.getenv('ERAS_PW')
FIRST_INGESTED_COMMENT_ID = os.getenv('FIRST_COMMENT_ID')


with psycopg.connect(f"host={TALK_CONN} port={TALK_PORT} dbname={TALK_DB} user={TALK_USER} password={TALK_PW} sslmode=require") as talk_db_conn, psycopg.connect(f"host={TIMESCALE_CONNECTION} port={TIMESCALE_PORT} dbname={ERAS_DB} user={ERAS_USER} password={ERAS_PW} sslmode=require") as timescale_db_conn:
  with talk_db_conn.cursor(name="talk").copy("COPY (SELECT id::bigint as comment_id, created_at as event_time, updated_at as comment_updated_at, project_id::bigint, user_id::bigint, created_at, updated_at from comments where id < %s}) TO STDOUT (FORMAT BINARY)", (FIRST_INGESTED_COMMENT_ID,)) as talk_copy:
        with timescale_db_conn.cursor().copy("COPY comment_events FROM STDIN (FORMAT BINARY)") as timescale_copy:
            for data in talk_copy:
                timescale_copy.write(data)