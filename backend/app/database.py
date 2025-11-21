import psycopg2
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
from app.config import settings

class Database:
    def __init__(self):
        self.connection_params = settings.database_url.replace('postgresql://', '')
        parts = self.connection_params.split('@')
        user_pass = parts[0].split(':')
        host_db = parts[1].split('/')
        host_port = host_db[0].split(':')
        
        self.params = {
            'user': user_pass[0],
            'password': user_pass[1],
            'host': host_port[0],
            'port': host_port[1] if len(host_port) > 1 else '5432',
            'database': host_db[1]
        }
    
    @contextmanager
    def get_db_connection(self):
        """Context manager para conexões com o banco"""
        conn = psycopg2.connect(**self.params, cursor_factory=RealDictCursor)
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()
    
    @contextmanager
    def get_db_cursor(self):
        """Context manager para cursor do banco"""
        with self.get_db_connection() as conn:
            cursor = conn.cursor()
            try:
                yield cursor
            finally:
                cursor.close()

db = Database()
