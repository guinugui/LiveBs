#!/usr/bin/env python3
"""
Teste direto da função AI para verificar se o tipo de treino está sendo respeitado
"""
import sys
import os
import json

# Adicionar o diretório do projeto ao path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.ai_service import generate_workout_plan

def test_workout_type():
    print("🏋️  TESTE DIRETO DA FUNÇÃO AI")
    print("="*50)
    
    # Teste 1: Treino em casa
    home_data = {
        "age": 30,
        "weight": 75,
        "height": 175,
        "activity_level": "MODERADO",
        "objective": "EMAGRECER",
        "fitness_level": "intermediario",
        "workout_type": "home",  # CASA
        "days_per_week": 3,
        "session_duration": 45,
        "available_days": ["Segunda", "Quarta", "Sexta"],
        "preferred_exercises": ["flexão", "agachamento"],
        "exercises_to_avoid": [],
        "has_musculoskeletal_problems": False,
        "has_respiratory_problems": False,
        "has_cardiac_problems": False,
        "previous_injuries": []
    }
    
    print("\n🏠 TESTE: TREINO EM CASA")
    print(f"Tipo solicitado: {home_data['workout_type']}")
    
    try:
        result = generate_workout_plan(home_data)
        print("✅ Plano gerado com sucesso!")
        
        # Analisar o resultado
        if 'days' in result:
            days = result['days']
            print(f"📅 Encontrados {len(days)} dias de treino")
            
            if days:
                first_day = days[0]
                exercises = first_day.get('exercises', [])
                print(f"\n💪 Exercícios do primeiro dia:")
                
                # Palavras que indicam equipamento de academia
                gym_indicators = [
                    'supino', 'leg press', 'máquina', 'barra olímpica', 'cabo', 'polia', 
                    'smith', 'cross over', 'peck deck', 'cadeira extensora', 'mesa flexora',
                    'aparelho', 'equipamento', 'halter de 20kg', 'halter pesado'
                ]
                
                # Palavras que indicam treino em casa  
                home_indicators = [
                    'flexão', 'agachamento', 'peso corporal', 'sem equipamentos',
                    'polichinelo', 'prancha', 'abdominais', 'burpee', 'mountain climber'
                ]
                
                issues_found = 0
                
                for i, ex in enumerate(exercises):
                    name = ex.get('name', '').lower()
                    print(f"   {i+1}. {ex.get('name', 'N/A')}")
                    print(f"      Sets: {ex.get('sets', 'N/A')} | Reps: {ex.get('reps', 'N/A')}")
                    
                    # Verificar se há equipamento inadequado
                    has_gym_equipment = any(indicator in name for indicator in gym_indicators)
                    is_bodyweight = any(indicator in name for indicator in home_indicators)
                    
                    if has_gym_equipment:
                        print(f"      ❌ PROBLEMA: Exercício requer equipamento de academia!")
                        issues_found += 1
                    elif is_bodyweight or 'halter' in name:
                        print(f"      ✅ OK: Adequado para treino em casa")
                    else:
                        print(f"      ⚠️  NEUTRO: Verificar se é adequado")
                
                print(f"\n📊 ANÁLISE:")
                print(f"   Exercícios inadequados encontrados: {issues_found}")
                if issues_found == 0:
                    print(f"   ✅ SUCESSO: Todos os exercícios são adequados para casa!")
                else:
                    print(f"   ❌ PROBLEMA: Encontrados exercícios de academia em treino de casa!")
        
        # Teste 2: Treino na academia
        print("\n" + "="*50)
        
        gym_data = home_data.copy()
        gym_data['workout_type'] = 'gym'
        gym_data['preferred_exercises'] = ['supino', 'leg press']
        
        print("\n🏢 TESTE: TREINO NA ACADEMIA")
        print(f"Tipo solicitado: {gym_data['workout_type']}")
        
        result_gym = generate_workout_plan(gym_data)
        print("✅ Plano de academia gerado com sucesso!")
        
        if 'days' in result_gym:
            days = result_gym['days']
            if days:
                first_day = days[0]
                exercises = first_day.get('exercises', [])
                print(f"\n💪 Exercícios do primeiro dia (academia):")
                
                for i, ex in enumerate(exercises[:3]):
                    name = ex.get('name', '').lower()
                    print(f"   {i+1}. {ex.get('name', 'N/A')}")
                    
                    has_equipment = any(indicator in name for indicator in gym_indicators)
                    if has_equipment:
                        print(f"      ✅ OK: Usando equipamento de academia")
                    else:
                        print(f"      ⚠️  Exercício básico (OK para academia também)")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    test_workout_type()