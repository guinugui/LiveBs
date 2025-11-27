#!/usr/bin/env python3
"""
Teste do plano alimentar após implementação do código do GitHub
"""
import sys
import os

# Adicionar o diretório do projeto ao path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.ai_service import generate_meal_plan
from app.config import settings
import json

def test_meal_plan_generation():
    """Testa a geração de plano alimentar"""
    
    print("🧪 TESTANDO GERAÇÃO DE PLANO ALIMENTAR")
    print("=" * 60)
    
    # Perfil de teste do usuário
    test_profile = {
        'weight': 75.0,
        'height': 175,
        'age': 30,
        'target_weight': 70.0,
        'activity_level': 'moderado',
        'daily_calories': 1800,
        'dietary_restrictions': [],
        'dietary_preferences': []
    }
    
    print(f"📊 Perfil de teste:")
    print(f"  - Peso: {test_profile['weight']} kg")
    print(f"  - Altura: {test_profile['height']} cm")
    print(f"  - Idade: {test_profile['age']} anos")
    print(f"  - Meta: {test_profile['target_weight']} kg")
    print(f"  - Atividade: {test_profile['activity_level']}")
    print(f"  - Calorias: {test_profile['daily_calories']} kcal")
    print()
    
    try:
        print("🚀 Gerando plano alimentar...")
        print("   (isso pode levar alguns segundos)")
        print()
        
        # Gerar o plano
        meal_plan = generate_meal_plan(test_profile)
        
        print("✅ Plano alimentar gerado com sucesso!")
        print()
        
        # Analisar estrutura do plano
        print(f"📋 Estrutura do plano:")
        print(f"  - Tipo: {type(meal_plan)}")
        
        if isinstance(meal_plan, dict):
            print(f"  - Chaves: {list(meal_plan.keys())}")
            
            if 'days' in meal_plan:
                days = meal_plan['days']
                print(f"  - Total de dias: {len(days)}")
                
                for day_idx, day in enumerate(days):
                    if isinstance(day, dict):
                        print(f"  - Dia {day_idx + 1}:")
                        if 'day' in day:
                            print(f"    - Número: {day['day']}")
                        if 'meals' in day:
                            meals = day['meals']
                            print(f"    - Refeições: {len(meals)}")
                            
                            for meal_idx, meal in enumerate(meals):
                                if isinstance(meal, dict):
                                    meal_type = meal.get('type', f'meal_{meal_idx}')
                                    print(f"      - {meal_type}")
                                    
                                    # Mostrar grupos de alimentos se existirem
                                    for food_group in ['carbs_foods', 'protein_foods', 'fat_foods', 'vegetables']:
                                        if food_group in meal:
                                            foods = meal[food_group]
                                            print(f"        - {food_group}: {len(foods)} itens")
                                    
                                    # Se não tem grupos, mostrar outras chaves
                                    if not any(key in meal for key in ['carbs_foods', 'protein_foods', 'fat_foods', 'vegetables']):
                                        meal_keys = [k for k in meal.keys() if k != 'type']
                                        if meal_keys:
                                            print(f"        - Outras info: {meal_keys}")
            else:
                # Se não tem 'days', mostrar outras informações
                print(f"  - Estrutura alternativa detectada")
                
        print()
        print("🎉 TESTE CONCLUÍDO COM SUCESSO!")
        print()
        print("📝 Exemplo do primeiro dia/refeição:")
        
        # Mostrar exemplo do conteúdo
        if isinstance(meal_plan, dict):
            if 'days' in meal_plan and len(meal_plan['days']) > 0:
                first_day = meal_plan['days'][0]
                if isinstance(first_day, dict) and 'meals' in first_day and len(first_day['meals']) > 0:
                    first_meal = first_day['meals'][0]
                    print(json.dumps(first_meal, indent=2, ensure_ascii=False))
                else:
                    print(json.dumps(first_day, indent=2, ensure_ascii=False)[:500] + "...")
            else:
                print(json.dumps(meal_plan, indent=2, ensure_ascii=False)[:500] + "...")
        
        return True
        
    except Exception as e:
        print(f"\n❌ ERRO ao gerar plano alimentar:")
        print(f"   {type(e).__name__}: {str(e)}")
        print()
        print("🔍 Possíveis causas:")
        print("  1. Problema com a API Key da OpenAI")
        print("  2. Resposta da IA não está no formato JSON correto")
        print("  3. Problema de conectividade")
        print("  4. Limite de créditos da OpenAI")
        
        return False

def main():
    """Função principal"""
    print("🔧 TESTE DE CORREÇÃO DO PLANO ALIMENTAR")
    print("Baseado no código do repositório GitHub")
    print()
    
    # Verificar se temos API Key
    if not hasattr(settings, 'openai_api_key') or not settings.openai_api_key:
        print("❌ API Key da OpenAI não configurada!")
        print("Configure a OPENAI_API_KEY no arquivo .env")
        return
    
    print(f"✅ API Key configurada: {settings.openai_api_key[:10]}...")
    print()
    
    # Executar teste
    success = test_meal_plan_generation()
    
    if success:
        print()
        print("🎯 PRÓXIMOS PASSOS:")
        print("1. Teste criando um plano pelo app Flutter")
        print("2. Verifique se os dados estão sendo salvos corretamente")
        print("3. Teste a visualização dos planos salvos")
        print()
    else:
        print()
        print("🔧 PARA CORRIGIR:")
        print("1. Verifique o error_response.txt para detalhes")
        print("2. Confirme se a API Key da OpenAI está válida")
        print("3. Teste a conectividade com a OpenAI")
        print()

if __name__ == "__main__":
    main()