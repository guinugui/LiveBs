#!/usr/bin/env python3
"""
Teste direto da função AI sem passar pelo roteador
"""
import sys
sys.path.append('.')

from app.ai_service import generate_workout_plan

# Dados de teste
test_data = {
    "fitness_level": "intermediario",
    "workout_type": "home",
    "days_per_week": 3,
    "session_duration": 45,
    "preferred_exercises": ["flexão"],
    "exercises_to_avoid": [],
    "has_musculoskeletal_problems": False,
    "has_respiratory_problems": False,
    "has_cardiac_problems": False,
    "previous_injuries": []
}

print(f"🧪 TESTE DIRETO DO AI")
print(f"Tipo solicitado: {test_data['workout_type']}")

try:
    result = generate_workout_plan(test_data)
    
    print(f"\n✅ Resposta do AI:")
    print(f"📝 plan_name: {result.get('plan_name', 'N/A')}")
    print(f"📋 plan_summary: {result.get('plan_summary', 'N/A')}")
    print(f"🎯 workout_type: {result.get('workout_type', 'N/A')}")
    print(f"🗂️ Estrutura: {list(result.keys())}")
    
    # Verificar se tem days ou workout_schedule
    if 'days' in result:
        print(f"📅 'days' encontrado: {len(result['days'])} dias")
    elif 'workout_schedule' in result:
        print(f"📅 'workout_schedule' encontrado: {len(result['workout_schedule'])} dias")
    else:
        print(f"❌ Nenhuma estrutura de dias encontrada!")
        
except Exception as e:
    print(f"❌ Erro: {e}")
    import traceback
    traceback.print_exc()