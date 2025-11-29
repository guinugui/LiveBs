import asyncpg
import redis
from typing import Optional
import os
from dotenv import load_dotenv
import asyncio
from contextlib import asynccontextmanager

load_dotenv()

# Fallback para desenvolvimento sem Redis
try:
    from app.mock_redis import MockRedis
except ImportError:
    MockRedis = None

class AsyncDatabase:
    """Classe para gerenciar pool de conexões assíncronas com PostgreSQL"""
    
    def __init__(self):
        self.pool: Optional[asyncpg.Pool] = None
        self.redis_client: Optional[redis.Redis] = None
        
        # Configurações do pool
        self.db_host = os.getenv('DB_HOST', '127.0.0.1')
        self.db_port = int(os.getenv('DB_PORT', 5432))
        self.db_name = os.getenv('DB_NAME', 'livebs_db')
        self.db_user = os.getenv('DB_USER', 'postgres')
        self.db_password = os.getenv('DB_PASSWORD')
        
        # Configurações do pool
        self.min_size = int(os.getenv('DB_POOL_MIN_SIZE', 10))
        self.max_size = int(os.getenv('DB_POOL_MAX_SIZE', 100))
        self.command_timeout = int(os.getenv('DB_COMMAND_TIMEOUT', 60))
        
        # Redis config
        self.redis_host = os.getenv('REDIS_HOST', '127.0.0.1')
        self.redis_port = int(os.getenv('REDIS_PORT', 6379))
        self.redis_db = int(os.getenv('REDIS_DB', 0))
        self.redis_password = os.getenv('REDIS_PASSWORD') or None
        
    async def connect(self):
        """Conecta ao PostgreSQL e Redis"""
        try:
            # Criar pool PostgreSQL
            self.pool = await asyncpg.create_pool(
                host=self.db_host,
                port=self.db_port,
                database=self.db_name,
                user=self.db_user,
                password=self.db_password,
                min_size=self.min_size,
                max_size=self.max_size,
                command_timeout=self.command_timeout
            )
            print(f"[ASYNC_DB] ✅ Pool PostgreSQL criado: {self.min_size}-{self.max_size} conexões")
            
            # Tentar conectar Redis real primeiro
            try:
                self.redis_client = redis.Redis(
                    host=self.redis_host,
                    port=self.redis_port,
                    db=self.redis_db,
                    password=self.redis_password,
                    decode_responses=True,
                    socket_connect_timeout=5,
                    socket_timeout=5,
                    retry_on_timeout=True
                )
                
                # Testar Redis
                await asyncio.get_event_loop().run_in_executor(
                    None, self.redis_client.ping
                )
                print("[ASYNC_DB] ✅ Redis real conectado com sucesso")
                
            except Exception as redis_error:
                print(f"[ASYNC_DB] ⚠️ Redis real falhou ({redis_error}), usando MockRedis")
                if MockRedis:
                    self.redis_client = MockRedis()
                    print("[ASYNC_DB] ✅ MockRedis ativo para desenvolvimento")
                else:
                    print("[ASYNC_DB] ❌ Nem Redis real nem MockRedis disponível")
                    raise redis_error
            
        except Exception as e:
            print(f"[ASYNC_DB] ❌ Erro na conexão: {e}")
            raise
            
    async def disconnect(self):
        """Desconecta do banco e Redis"""
        if self.pool:
            await self.pool.close()
            print("[ASYNC_DB] 🔌 Pool PostgreSQL fechado")
            
        if self.redis_client:
            self.redis_client.close()
            print("[ASYNC_DB] 🔌 Redis desconectado")
    
    @asynccontextmanager
    async def get_connection(self):
        """Context manager para obter conexão do pool"""
        async with self.pool.acquire() as conn:
            yield conn
    
    async def execute_query(self, query: str, *args):
        """Executa query simples"""
        async with self.get_connection() as conn:
            return await conn.fetch(query, *args)
    
    async def execute_one(self, query: str, *args):
        """Executa query retornando um resultado"""
        async with self.get_connection() as conn:
            return await conn.fetchrow(query, *args)
    
    async def execute_command(self, query: str, *args):
        """Executa comando (INSERT, UPDATE, DELETE)"""
        async with self.get_connection() as conn:
            return await conn.execute(query, *args)
    
    # Cache methods
    async def cache_get(self, key: str):
        """Busca valor do cache"""
        try:
            return await asyncio.get_event_loop().run_in_executor(
                None, self.redis_client.get, key
            )
        except Exception as e:
            print(f"[CACHE] ⚠️ Erro ao buscar {key}: {e}")
            return None
    
    async def cache_set(self, key: str, value: str, ttl: int = None):
        """Armazena valor no cache"""
        try:
            ttl = ttl or int(os.getenv('CACHE_TTL', 3600))
            await asyncio.get_event_loop().run_in_executor(
                None, self.redis_client.setex, key, ttl, value
            )
        except Exception as e:
            print(f"[CACHE] ⚠️ Erro ao salvar {key}: {e}")
    
    async def cache_delete(self, key: str):
        """Remove valor do cache"""
        try:
            await asyncio.get_event_loop().run_in_executor(
                None, self.redis_client.delete, key
            )
        except Exception as e:
            print(f"[CACHE] ⚠️ Erro ao deletar {key}: {e}")

# Instância global
async_db = AsyncDatabase()