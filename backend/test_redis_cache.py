#!/usr/bin/env python3
"""
🔍 TESTE DE CACHE REDIS - LiveBs Backend
Verifica se Redis está funcionando corretamente ou se está usando MockRedis
"""

import asyncio
import json
import time
from datetime import datetime
import sys
import os

# Adicionar o diretório app ao path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app.async_database import async_db
from app.cache_manager import cache_manager
from app.token_manager import token_manager

class RedisTestSuite:
    """Suite de testes para verificar o Redis"""
    
    def __init__(self):
        self.tests_passed = 0
        self.tests_failed = 0
        self.redis_type = "Unknown"
    
    async def setup(self):
        """Conecta ao banco e Redis"""
        try:
            await async_db.connect()
            
            # Identificar tipo de Redis
            if hasattr(async_db.redis_client, '_mock_data'):
                self.redis_type = "MockRedis (Desenvolvimento)"
            else:
                self.redis_type = "Redis Real (Produção)"
                
            print(f"🔧 SETUP: Usando {self.redis_type}")
            return True
        except Exception as e:
            print(f"❌ SETUP FALHOU: {e}")
            return False
    
    async def cleanup(self):
        """Desconecta do banco e Redis"""
        await async_db.disconnect()
        print("🧹 CLEANUP: Conexões fechadas")
    
    def log_test(self, test_name: str, success: bool, details: str = ""):
        """Log do resultado do teste"""
        status = "✅" if success else "❌"
        print(f"{status} {test_name}: {details}")
        
        if success:
            self.tests_passed += 1
        else:
            self.tests_failed += 1
    
    async def test_basic_cache_operations(self):
        """Teste 1: Operações básicas de cache"""
        print("\n🧪 TESTE 1: Operações básicas de cache")
        
        try:
            # Set
            test_key = "test:basic"
            test_value = "Hello Redis!"
            await async_db.cache_set(test_key, test_value, 60)
            
            # Get
            retrieved = await async_db.cache_get(test_key)
            
            if retrieved == test_value:
                self.log_test("Cache SET/GET", True, f"Valor '{test_value}' armazenado e recuperado")
            else:
                self.log_test("Cache SET/GET", False, f"Esperado '{test_value}', obtido '{retrieved}'")
            
            # Delete
            await async_db.cache_delete(test_key)
            deleted_check = await async_db.cache_get(test_key)
            
            if deleted_check is None:
                self.log_test("Cache DELETE", True, "Chave deletada com sucesso")
            else:
                self.log_test("Cache DELETE", False, f"Chave ainda existe: {deleted_check}")
                
        except Exception as e:
            self.log_test("Operações básicas", False, f"Erro: {e}")
    
    async def test_cache_manager_profile(self):
        """Teste 2: Cache Manager - Perfil de usuário"""
        print("\n🧪 TESTE 2: Cache Manager - Perfil")
        
        try:
            user_id = "test_user_123"
            profile_data = {
                "name": "João Teste", 
                "age": 25, 
                "created_at": datetime.now().isoformat()
            }
            
            # Salvar perfil
            await cache_manager.set_user_profile(user_id, profile_data)
            
            # Recuperar perfil
            cached_profile = await cache_manager.get_user_profile(user_id)
            
            if cached_profile and cached_profile["name"] == profile_data["name"]:
                self.log_test("Profile Cache", True, f"Perfil de {cached_profile['name']} cacheado")
            else:
                self.log_test("Profile Cache", False, f"Perfil não recuperado corretamente")
            
            # Limpar cache do usuário
            await cache_manager.invalidate_user_cache(user_id)
            invalidated = await cache_manager.get_user_profile(user_id)
            
            if invalidated is None:
                self.log_test("Profile Invalidation", True, "Cache do usuário invalidado")
            else:
                self.log_test("Profile Invalidation", False, "Cache não foi invalidado")
                
        except Exception as e:
            self.log_test("Cache Manager Profile", False, f"Erro: {e}")
    
    async def test_cache_manager_ai_response(self):
        """Teste 3: Cache Manager - Resposta da IA"""
        print("\n🧪 TESTE 3: Cache Manager - IA Response")
        
        try:
            prompt = "Crie um plano alimentar para emagrecer"
            ai_response = {
                "message": "Aqui está seu plano alimentar personalizado...",
                "tokens_used": 150,
                "generated_at": datetime.now().isoformat()
            }
            
            # Salvar resposta da IA
            prompt_hash = await cache_manager.set_ai_response(prompt, ai_response)
            
            # Recuperar resposta
            cached_ai = await cache_manager.get_ai_response(prompt_hash)
            
            if cached_ai and cached_ai["tokens_used"] == 150:
                self.log_test("AI Response Cache", True, f"IA response cacheada (hash: {prompt_hash})")
            else:
                self.log_test("AI Response Cache", False, "IA response não recuperada")
                
        except Exception as e:
            self.log_test("AI Response Cache", False, f"Erro: {e}")
    
    async def test_token_manager(self):
        """Teste 4: Token Manager"""
        print("\n🧪 TESTE 4: Token Manager")
        
        try:
            user_id = "test_user_456"
            
            # Verificar tokens disponíveis (usuário novo)
            available = await token_manager.get_available_tokens(user_id)
            
            if available == 50000:  # Default limit
                self.log_test("Token Initial Limit", True, f"Limite inicial: {available} tokens")
            else:
                self.log_test("Token Initial Limit", False, f"Limite inesperado: {available}")
            
            # Consumir tokens
            tokens_used = 1500
            success = await token_manager.consume_tokens(user_id, tokens_used)
            
            if success:
                remaining = await token_manager.get_available_tokens(user_id)
                expected = 50000 - tokens_used
                
                if remaining == expected:
                    self.log_test("Token Consumption", True, f"Consumiu {tokens_used}, restam {remaining}")
                else:
                    self.log_test("Token Consumption", False, f"Esperado {expected}, obtido {remaining}")
            else:
                self.log_test("Token Consumption", False, "Falha ao consumir tokens")
                
        except Exception as e:
            self.log_test("Token Manager", False, f"Erro: {e}")
    
    async def test_performance(self):
        """Teste 5: Performance do cache"""
        print("\n🧪 TESTE 5: Performance")
        
        try:
            # Teste de múltiplas operações
            start_time = time.time()
            
            operations = []
            for i in range(10):
                key = f"perf_test:{i}"
                value = f"Performance test value {i}"
                operations.append(async_db.cache_set(key, value, 60))
            
            # Executar todas as operações em paralelo
            await asyncio.gather(*operations)
            
            # Recuperar todas as chaves
            get_operations = []
            for i in range(10):
                key = f"perf_test:{i}"
                get_operations.append(async_db.cache_get(key))
            
            results = await asyncio.gather(*get_operations)
            
            end_time = time.time()
            duration = round((end_time - start_time) * 1000, 2)  # ms
            
            # Verificar se todos os valores foram recuperados
            all_success = all(results[i] == f"Performance test value {i}" for i in range(10))
            
            if all_success:
                self.log_test("Performance Test", True, f"10 ops SET/GET em {duration}ms")
            else:
                self.log_test("Performance Test", False, f"Algumas operações falharam")
            
            # Limpar dados de teste
            for i in range(10):
                await async_db.cache_delete(f"perf_test:{i}")
                
        except Exception as e:
            self.log_test("Performance Test", False, f"Erro: {e}")
    
    async def test_ttl_expiration(self):
        """Teste 6: Expiração TTL (apenas teste conceitual)"""
        print("\n🧪 TESTE 6: TTL Expiration")
        
        try:
            test_key = "test:ttl"
            test_value = "This should expire"
            
            # Set com TTL muito baixo (2 segundos)
            await async_db.cache_set(test_key, test_value, 2)
            
            # Verificar que existe
            immediate_check = await async_db.cache_get(test_key)
            
            if immediate_check == test_value:
                self.log_test("TTL Set", True, "Valor definido com TTL de 2s")
                
                # Aguardar expiração
                print("   ⏳ Aguardando 3 segundos para expiração...")
                await asyncio.sleep(3)
                
                # Verificar se expirou
                expired_check = await async_db.cache_get(test_key)
                
                if expired_check is None:
                    self.log_test("TTL Expiration", True, "Valor expirou corretamente")
                else:
                    self.log_test("TTL Expiration", False, f"Valor ainda existe: {expired_check}")
            else:
                self.log_test("TTL Set", False, "Falha ao definir valor com TTL")
                
        except Exception as e:
            self.log_test("TTL Test", False, f"Erro: {e}")
    
    async def run_all_tests(self):
        """Executa todos os testes"""
        print("🚀 INICIANDO TESTES DE REDIS/CACHE")
        print("=" * 50)
        
        if not await self.setup():
            return
        
        try:
            await self.test_basic_cache_operations()
            await self.test_cache_manager_profile()
            await self.test_cache_manager_ai_response()
            await self.test_token_manager()
            await self.test_performance()
            await self.test_ttl_expiration()
            
        finally:
            await self.cleanup()
        
        # Relatório final
        print("\n" + "=" * 50)
        print("📊 RELATÓRIO FINAL")
        print(f"🎯 Redis Type: {self.redis_type}")
        print(f"✅ Testes Passou: {self.tests_passed}")
        print(f"❌ Testes Falhou: {self.tests_failed}")
        print(f"📈 Taxa Sucesso: {(self.tests_passed/(self.tests_passed+self.tests_failed)*100):.1f}%")
        
        if self.tests_failed == 0:
            print("🎉 TODOS OS TESTES PASSARAM! Redis está funcionando perfeitamente.")
        else:
            print(f"⚠️  Alguns testes falharam. Verifique a configuração do Redis.")

async def main():
    """Função principal"""
    test_suite = RedisTestSuite()
    await test_suite.run_all_tests()

if __name__ == "__main__":
    asyncio.run(main())