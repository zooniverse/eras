import os
import argparse
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

now = datetime.now()

current_time = now.strftime("%H:%M:%S")
print("BEFORE Time =", current_time)
sc
parser = argparse.ArgumentParser()
parser.add_argument("-ug", "--user_group_id", type=int)
parser.add_argument('email_domain_formats')

args = parser.parse_args()
user_group_id = args.user_group_id
# email formats in form of comma separated string with no spaces (eg. "%a.com,%b.org%")
email_formats = args.email_domain_formats

panoptes_db_conn = psycopg.connect(f"host={PANOPTES_CONN} port={PANOPTES_PORT} dbname={PANOPTES_DB} user={PANOPTES_USER} password={PANOPTES_PW} sslmode=require")
panoptes_cursor = panoptes_db_conn.cursor()

eras_conn = psycopg.connect(f"host={TIMESCALE_CONNECTION} port={TIMESCALE_PORT} dbname={ERAS_DB} user={ERAS_USER} password={ERAS_PW} sslmode=require")
eras_cursor = eras_conn.cursor()

# get ids of users that are not in group yet
panoptes_cursor.execute("SELECT id from users where email ILIKE ANY(STRING_TO_ARRAY(%s, ',')) AND id NOT IN (SELECT user_id from memberships where user_group_id=%s)", (email_formats, user_group_id))

not_in_group_yet_user_ids = [result[0] for result in panoptes_cursor.fetchall()]

if len(not_in_group_yet_user_ids) > 0:
    # create memberships to user group
    memberships_to_create = list(map(lambda user_id: (user_group_id, user_id, 'active', '{"group_member"}'),not_in_group_yet_user_ids))
    panoptes_cursor.executemany("INSERT INTO memberships (user_group_id, user_id, state, roles) VALUES  (%s,%s,%s,%s)", memberships_to_create)

    panoptes_db_conn.commit()

    # eras get classification_events of not_in_group_yet_user_ids that does not have user_group_id within their user_group_ids classification_event
    eras_cursor.execute("SELECT classification_id, event_time, session_time, project_id, user_id, workflow_id, created_at, updated_at, user_group_ids from classification_events WHERE user_id IN %s AND %s!=ANY(user_group_ids)", (not_in_group_yet_user_ids, user_group_id))
    classification_events_to_backfill = eras_cursor.fetchall()

    # create classification_user_group
    classification_user_groups = list(map(lambda classification: (classification[0:8] + (user_group_id,)), classification_events_to_backfill))
    eras_cursor.executemany("INSERT INTO classification_user_groups (classification_id, event_time, session_time, project_id, user_id, workflow_id, created_at, updated_at, user_group_id) VALUES  (%s,%s,%s,%s,%s,%s,%s,%s,%s)", classification_user_groups)

    # update classification_events' user_group_ids so that it includes new classification_id
    classification_events_to_update = list(map(lambda classification_event: {'classification_id': classification_event[0], 'user_group_ids': ([user_group_id] if classification_event[8] is None else classification_event[8] +[user_group_id])} ,classification_events_to_backfill))
    eras_cursor.executemany("UPDATE classification_events SET user_group_ids = %(user_group_ids)s WHERE classification_id = %(classification_id)s", classification_events_to_update)

    eras_conn.commit()

panoptes_cursor.close()
panoptes_db_conn.close()
eras_cursor.close()
eras_conn.close()


finish = datetime.now()
finish_time = finish.strftime("%H:%M:%S")
print("AFTER Time =", finish_time)

