import MySQLdb
import server.utils as utils

DB_HOST = None
DB_USER = None
DB_PASSWORD = None
DB_DB = None
SETUP_CONFIG = False

def setup(host, user, password, db):
    global DB_HOST, DB_USER, DB_PASSWORD, DB_DB, SETUP_CONFIG
    DB_HOST = host
    DB_USER = user
    DB_PASSWORD = password
    DB_DB = db
    SETUP_CONFIG = True

def run_query(query, params, _retrying=False):
    if not SETUP_CONFIG:
        raise Exception("You forgot to call setup in db_backend")

    conn = MySQLdb.connect(host=DB_HOST, user=DB_USER, passwd=DB_PASSWORD, db=DB_DB,
                           charset="utf-8")
    cursor = conn.cursor()
    cursor.execute(query, params)
    results = cursor.fetchall()
    cursor.close()
    conn.commit()
    conn.close()
    return results
