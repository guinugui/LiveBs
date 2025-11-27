import pg8000.native
import sqlite3
from contextlib import contextmanager
import uuid
import sys

class Database:
    def __init__(self):
        self.use_postgres = False
        self.db_path = "nutri_ai.db"
        
        # FORÇAR PostgreSQL usando pg8000 (puro Python)
        print("[DATABASE] 🔧 Conectando PostgreSQL com pg8000...")
        
        try:
            # Testar conexão com pg8000
            test_conn = pg8000.native.Connection(
                host="127.0.0.1",
                port=5432,
                database="livebs_db",
                user="postgres",
                password="MCguinu02"
            )
            
            # Testar query simples
            result = test_conn.run("SELECT 1")
            print(f"[DATABASE] ✅ pg8000 conectado! Teste: {result}")
            test_conn.close()
            
            self.use_postgres = True
            self.init_postgres_tables()
            
        except Exception as e:
            print(f"[DATABASE] ❌ ERRO pg8000: {e}")
            print(f"[DATABASE] 🔍 Tipo: {type(e)}")
            print("[DATABASE] 💀 PostgreSQL é OBRIGATÓRIO - não posso continuar!")
            sys.exit(1)
    
    def init_postgres_tables(self):
        """Inicializar tabelas PostgreSQL com pg8000"""
        print("[DATABASE] 📋 Conectando em livebs_db com pg8000...")
        
        # Conectar no banco
        conn = pg8000.native.Connection(
            host="127.0.0.1",
            port=5432,
            database="livebs_db",
            user="postgres",
            password="MCguinu02"
        )
        
        # Verificar versão
        version = conn.run("SELECT version()")
        print(f"[DATABASE] 🐘 PostgreSQL: {version[0][0][:50]}...")
        
        # Verificar tabelas existentes 
        tables = conn.run("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
        print(f"[DATABASE] 📋 Tabelas encontradas: {len(tables)}")
        for table in tables[:5]:
            print(f"[DATABASE] - {table[0]}")
            
        conn.close()
        print("[DATABASE] ✅ PostgreSQL inicializado com pg8000!")
    
    def init_sqlite_tables(self):
        """Inicializar tabelas SQLite"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                email TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                name TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS saved_workout_plans (
                id TEXT PRIMARY KEY,
                user_id TEXT REFERENCES users(id),
                plan_name TEXT NOT NULL,
                workout_type TEXT NOT NULL,
                days_per_week INTEGER NOT NULL,
                plan_content TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        conn.commit()
        conn.close()
        print("[DATABASE] ✅ SQLite inicializado como fallback")
    
    @contextmanager
    def get_db_connection(self):
        """Context manager para conexões (PostgreSQL ou SQLite)"""
        if self.use_postgres:
            conn = None
            try:
                conn = pg8000.native.Connection(
                    host="127.0.0.1",
                    port=5432,
                    database="livebs_db",
                    user="postgres",
                    password="MCguinu02"
                )
                yield conn
                # pg8000 não tem commit/rollback manual no modo native
            except Exception as e:
                print(f"[DATABASE] ❌ Erro pg8000: {e}")
                raise
            finally:
                if conn:
                    conn.close()
        else:
            conn = None
            try:
                conn = sqlite3.connect(self.db_path)
                conn.row_factory = sqlite3.Row
                yield conn
                conn.commit()
            except Exception as e:
                print(f"[DATABASE] ❌ Erro SQLite: {e}")
                if conn:
                    conn.rollback()
                raise
            finally:
                if conn:
                    conn.close()
    
    class PG8000Cursor:
        """Wrapper para simular cursor do psycopg2 com pg8000"""
        def __init__(self, conn):
            self.conn = conn
            self.last_result = None
            self.column_names = []
            
        def execute(self, query, params=None):
            # Converter %s para :param1, :param2... para pg8000
            if '%s' in query and params:
                pg8000_query = query
                param_dict = {}
                for i in range(len(params)):
                    param_name = f'param{i+1}'
                    pg8000_query = pg8000_query.replace('%s', f':{param_name}', 1)
                    param_dict[param_name] = params[i]
                self.last_result = self.conn.run(pg8000_query, **param_dict)
            elif params:
                self.last_result = self.conn.run(query, **params)
            else:
                self.last_result = self.conn.run(query)
            
            # Extrair nomes das colunas da query SELECT
            if query.strip().upper().startswith('SELECT'):
                self._extract_column_names(query)
        
        def _extract_column_names(self, query):
            """Extrair nomes das colunas de uma query SELECT"""
            try:
                # Extrair parte entre SELECT e FROM
                select_part = query.split('SELECT')[1].split('FROM')[0]
                columns = [col.strip().split('.')[-1] for col in select_part.split(',')]
                self.column_names = [col.strip() for col in columns]
            except:
                self.column_names = []
        
        def fetchone(self):
            if self.last_result and len(self.last_result) > 0:
                row = self.last_result[0]
                # Criar dict com nomes das colunas se possível
                if self.column_names and len(self.column_names) == len(row):
                    return dict(zip(self.column_names, row))
                # Senão, retornar lista mesmo
                return row
            return None
        
        def fetchall(self):
            if not self.last_result:
                return []
            # Retornar lista de dicts se temos nomes das colunas
            if self.column_names:
                return [dict(zip(self.column_names, row)) for row in self.last_result]
            return self.last_result
            
        def close(self):
            pass
    
    @contextmanager  
    def get_db_cursor(self):
        """Context manager para cursor"""
        if self.use_postgres:
            with self.get_db_connection() as conn:
                cursor = self.PG8000Cursor(conn)
                try:
                    yield cursor
                finally:
                    cursor.close()
        else:
            with self.get_db_connection() as conn:
                cursor = conn.cursor()
                try:
                    yield cursor
                finally:
                    cursor.close()
    
    def get_param_placeholder(self):
        """Retorna o placeholder correto (%s para PostgreSQL via pg8000, ? para SQLite)"""
        return "%s" if self.use_postgres else "?"

db = Database()