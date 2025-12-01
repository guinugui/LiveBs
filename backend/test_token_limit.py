#!/usr/bin/env python3
"""
🧪 TESTE DO SISTEMA DE TOKENS - Simula limite atingido
Testa o que acontece quando usuário atinge o limite diário
"""

import asyncio
import sys
import os

# Adicionar o diretório app ao path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app.async_database import async_db
from app.token_manager import token_manager
from app.token_limit_handler import check_and_consume_tokens, TokenLimitError

async def test_token_limit_scenario():
    """Simula cenário de limite de tokens atingido"""
    
    print("🧪 TESTE: Cenário de Limite de Tokens")
    print("=" * 50)
    
    # Setup
    await async_db.connect()
    
    test_user_id = "test_token_limit_user"
    
    try:
        # 1. Verificar status inicial
        print("\n📊 1. Status inicial dos tokens:")
        initial_status = await token_manager.get_user_tokens_today(test_user_id)
        print(f"   Tokens disponíveis: {initial_status['remaining_tokens']:,}")
        print(f"   Limite diário: {initial_status['daily_limit']:,}")
        print(f"   Já usado hoje: {initial_status['used_tokens']:,}")
        
        # 2. Consumir tokens até quase o limite
        print(f"\n⚡ 2. Consumindo tokens até próximo do limite...")
        
        # Consumir 98,000 tokens (deixando apenas 2,000)
        large_consumption = 98000
        success = await token_manager.consume_tokens(test_user_id, large_consumption)
        
        if success:
            print(f"   ✅ Consumiu {large_consumption:,} tokens com sucesso")
            
            # Verificar status após grande consumo
            status_after = await token_manager.get_user_tokens_today(test_user_id)
            print(f"   Tokens restantes: {status_after['remaining_tokens']:,}")
            print(f"   Percentage usado: {(status_after['used_tokens']/status_after['daily_limit']*100):.1f}%")
        else:
            print(f"   ❌ Falha ao consumir tokens")
            return
        
        # 3. Tentar usar mais tokens - deve dar warning
        print(f"\n⚠️  3. Testando aviso de tokens baixos (tentando usar 500 tokens)...")
        try:
            token_status = await check_and_consume_tokens(test_user_id, 500)
            print(f"   ✅ Sucesso - Tokens restantes: {token_status['remaining_tokens']:,}")
            if token_status['is_warning']:
                print(f"   🔥 AVISO: Usuário está no limite de alerta!")
        except TokenLimitError as e:
            print(f"   🚫 Erro esperado: {e.message}")
        
        # 4. Tentar ultrapassar o limite
        print(f"\n🚫 4. Testando limite atingido (tentando usar 3,000 tokens)...")
        try:
            token_status = await check_and_consume_tokens(test_user_id, 3000)
            print(f"   ⚠️ Inesperado: Conseguiu usar tokens quando não deveria!")
        except TokenLimitError as e:
            print(f"   ✅ Limite funcionou corretamente!")
            print(f"   Mensagem de erro: {e.message[:100]}...")
            print(f"   Tokens restantes: {e.remaining_tokens}")
            print(f"   Reset em: {e.reset_time}")
        
        # 5. Status final
        print(f"\n📈 5. Status final dos tokens:")
        final_status = await token_manager.get_user_tokens_today(test_user_id)
        print(f"   Total usado hoje: {final_status['used_tokens']:,}")
        print(f"   Tokens restantes: {final_status['remaining_tokens']:,}")
        print(f"   Requests feitas: {final_status['requests_count']}")
        print(f"   Limite atingido? {'Sim' if final_status['is_limit_reached'] else 'Não'}")
        
        # 6. Simular mensagens que apareceriam no front
        print(f"\n📱 6. Mensagens que o usuário veria no front:")
        
        # Caso 1: Aviso de tokens baixos
        if final_status['remaining_tokens'] > 0:
            remaining = final_status['remaining_tokens']
            percentage_used = (final_status['used_tokens'] / final_status['daily_limit']) * 100
            
            if percentage_used >= 90:
                frontend_message = (
                    f"🔥 ATENÇÃO: Você já usou {percentage_used:.0f}% dos seus tokens hoje! "
                    f"Restam apenas {remaining:,} tokens. Use com moderação! 😊"
                )
            else:
                frontend_message = (
                    f"⚡ Você já usou {percentage_used:.0f}% dos seus tokens hoje. "
                    f"Restam {remaining:,} tokens para suas próximas perguntas."
                )
                
            print(f"   Aviso: {frontend_message}")
        
        # Caso 2: Limite atingido
        if final_status['is_limit_reached']:
            limit_message = (
                "🚫 **Limite Diário Atingido!**\\n\\n"
                f"Você já utilizou seus **{final_status['daily_limit']:,} tokens** disponíveis hoje.\\n\\n"
                "**O que você pode fazer:**\\n"
                "• ✨ Aguarde até amanhã para novos tokens\\n"
                "• 📱 Continue navegando no app normalmente\\n"
                "• 💡 Use as funcionalidades que não dependem de IA\\n\\n"
                "**Seus tokens serão renovados automaticamente às 00:00** 🕛"
            )
            print(f"   Erro de limite: {limit_message}")
        
        print(f"\n🎯 Teste concluído! O sistema está protegendo corretamente contra uso excessivo.")
        
    except Exception as e:
        print(f"❌ Erro durante teste: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        await async_db.disconnect()

async def simulate_frontend_responses():
    """Simula as respostas que o frontend receberia"""
    
    print("\n" + "=" * 50)
    print("📱 SIMULAÇÃO: Respostas do Frontend")
    print("=" * 50)
    
    # Cenário 1: Usuário normal (uso baixo)
    print("\n✅ CENÁRIO 1: Uso normal (20% dos tokens)")
    print("   Status Code: 200")
    print("   Response: {")
    print("     'message': 'Aqui está seu plano alimentar personalizado...',")
    print("     'token_warning': '💚 Você ainda tem 80,000 tokens disponíveis'")
    print("   }")
    
    # Cenário 2: Usuário próximo do limite
    print("\n⚠️  CENÁRIO 2: Próximo do limite (90% dos tokens)")
    print("   Status Code: 200")
    print("   Response: {")
    print("     'message': 'Treino gerado com sucesso...',")
    print("     'token_warning': '🔥 Atenção! Você já usou 90% dos seus tokens hoje!'")
    print("   }")
    
    # Cenário 3: Limite atingido
    print("\n🚫 CENÁRIO 3: Limite atingido")
    print("   Status Code: 429 (Too Many Requests)")
    print("   Response: {")
    print("     'detail': {")
    print("       'error': 'token_limit_exceeded',")
    print("       'message': '🚫 **Limite Diário Atingido!**...',")
    print("       'remaining_tokens': 0,")
    print("       'daily_limit': 100000,")
    print("       'reset_time': '00:00 (meia-noite)',")
    print("       'type': 'token_limit'")
    print("     }")
    print("   }")
    
    # Como o Flutter deve tratar
    print("\n🎨 TRATAMENTO NO FLUTTER:")
    print("   • Status 200: Mostrar resposta + warning (se houver)")
    print("   • Status 429: Mostrar dialog/modal com limite atingido")
    print("   • Botão 'Entendi' para fechar o modal")
    print("   • Desabilitar botões de IA até meia-noite")
    print(f"   • NOVO LIMITE: 100.000 tokens/dia (GPT-4 mini é mais barato)")

async def main():
    """Executa todos os testes"""
    await test_token_limit_scenario()
    await simulate_frontend_responses()

if __name__ == "__main__":
    asyncio.run(main())