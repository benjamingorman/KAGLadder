import MySQLdb as mariadb
import server.secrets as secrets

conn = mariadb.connect(host=secrets.DB_HOST, user=secrets.DB_USER, passwd=secrets.DB_PASS, db=secrets.DB_DB)

def get_conn():
    global conn
    conn.ping(reconnect=True) # do this to reboot the connection if it has been down for a while
    return conn

def run_query(query, params):
    with get_conn() as cursor:
        cursor.execute(query, params)

def get_one_row(query, params):
    with get_conn() as cursor:
        cursor.execute(query, params)
        result = cursor.fetchone()
    return result

def get_many_rows(query, params):
    with get_conn() as cursor:
        cursor.execute(query, params)
        results = cursor.fetchall()
    return results

def get_one_row_as_model(model_class, query, params):
    row = get_one_row(query, params)
    if row:
        return model_class.from_row(row)

def get_many_rows_as_models(model_class, query, params):
    models = []
    for row in get_many_rows(query, params):
        models.append(model_class.from_row(row))
    return models
