#!/usr/bin/env python3
"""
Script para limpar planos de treino antigos do banco
"""

import pg8000.native

def clear_old_plans():
    """Limpar todos os planos antigos salvos"""
    try:
        print("🗑️ Limpando planos antigos do banco...")
        
        # Conectar direto com pg8000
        conn = pg8000.native.Connection(
            host="127.0.0.1",
            port=5432,
            database="livebs_db",
            user="postgres",
            password="MCguinu02"
        )
        
        # Executar DELETE para limpar planos antigos
        result = conn.run("DELETE FROM saved_workout_plans")
        print("✅ Planos antigos removidos!")
        
        # Verificar quantos restaram
        result = conn.run("SELECT COUNT(*) FROM saved_workout_plans")
        count = result[0][0] if result else 0
        
        print(f"📊 Planos restantes no banco: {count}")
        
        conn.close()
        
        if count == 0:
            print("🎉 Banco limpo! Próximos planos serão gerados com 5-6 exercícios!")
            return True
        
    except Exception as e:
        print(f"❌ Erro ao limpar banco: {e}")
        return False
    
    return True

if __name__ == "__main__":
    clear_old_plans()