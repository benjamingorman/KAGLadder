import server.secrets as secrets
import server.main
import MySQLdb as mariadb

db_connection = mariadb.connect(host=secrets.DB_HOST, user=secrets.DB_USER, passwd=secrets.DB_PASS, db=secrets.DB_DB)
cursor = db_connection.cursor()
cursor.execute("SELECT * FROM player_rating WHERE username=%s AND region=%s AND kag_class=%s", ("Eluded", "EU", "knight"))
print(cursor.fetchone())

print(server.main.db_get_player_rating("Eluded", "EU", "knight"))
