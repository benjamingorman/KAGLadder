import MySQLdb
import server.secrets as secrets

def run_query(query, params, _retrying=False):
    conn = MySQLdb.connect(host=secrets.DB_HOST, user=secrets.DB_USER, passwd=secrets.DB_PASS, db=secrets.DB_DB)
    cursor = conn.cursor()
    cursor.execute(query, params)
    results = cursor.fetchall()
    cursor.close()
    conn.commit()
    conn.close()
    return results
