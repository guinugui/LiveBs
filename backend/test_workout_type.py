#!/usr/bin/env python3
"""
Teste específico para verificar se o tipo de treino (casa/academia) está sendo respeitado
"""
import requests
import json

# Dados de teste para treino em casa
test_data_home = {
    "age": 30,
    "weight": 75,
    "height": 175,
    "activity_level": "MODERADO",
    "objective": "EMAGRECER",
    "fitness_level": "intermediario",
    "workout_type": "home",  # CASA
    "days_per_week": 4,
    "session_duration": 45,
    "available_days": ["Segunda", "Terça", "Quinta", "Sexta"],
    "preferred_exercises": ["flexão", "agachamento"],
    "exercises_to_avoid": [],
    "has_musculoskeletal_problems": False,
    "has_respiratory_problems": False,
    "has_cardiac_problems": False,
    "previous_injuries": []
}

# Dados de teste para treino na academia
test_data_gym = {
    "age": 30,
    "weight": 75,
    "height": 175,
    "activity_level": "MODERADO",
    "objective": "EMAGRECER",
    "fitness_level": "intermediario",
    "workout_type": "gym",  # ACADEMIA
    "days_per_week": 4,
    "session_duration": 45,
    "available_days": ["Segunda", "Terça", "Quinta", "Sexta"],
    "preferred_exercises": ["supino", "leg press"],
    "exercises_to_avoid": [],
    "has_musculoskeletal_problems": False,
    "has_respiratory_problems": False,
    "has_cardiac_problems": False,
    "previous_injuries": []
}

def test_workout_generation(data, test_name):
    print(f"\n🧪 TESTE: {test_name}")
    print(f"Tipo de treino solicitado: {data['workout_type']}")
    
    try:
        # Fazer requisição para gerar plano de treino
        response = requests.post(
            "http://localhost:8001/workout-plan/",
            json=data,
            timeout=60
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Plano gerado com sucesso!")
            
            # Analisar se o tipo de treino foi respeitado
            if 'workout_data' in result and 'days' in result['workout_data']:
                days = result['workout_data']['days']
                print(f"📅 Dias de treino encontrados: {len(days)}")
                
                # Verificar exercícios do primeiro dia
                if days:
                    first_day = days[0]
                    exercises = first_day.get('exercises', [])
                    print(f"💪 Exercícios do primeiro dia:")
                    
                    gym_indicators = ['supino', 'leg press', 'máquina', 'barra', 'cabo']
                    home_indicators = ['flexão', 'agachamento', 'peso corporal', 'sem equipamentos']
                    
                    for ex in exercises[:3]:  # Mostrar apenas 3 exercícios
                        name = ex.get('name', '').lower()
                        print(f"   - {ex.get('name', 'N/A')}")
                        
                        # Verificar se está correto
                        if data['workout_type'] == 'home':
                            has_gym_equipment = any(indicator in name for indicator in gym_indicators)
                            if has_gym_equipment:
                                print(f"   ❌ ERRO: Exercício de academia em treino de casa!")
                        
                        elif data['workout_type'] == 'gym':
                            is_bodyweight = any(indicator in name for indicator in home_indicators)
                            if 'flexão' in name and 'máquina' not in name:
                                print(f"   ⚠️  AVISO: Exercício sem equipamento em treino de academia")
                
                # Mostrar resumo do plano
                if 'plan_summary' in result:
                    summary = result['plan_summary']
                    print(f"\n📋 Resumo do plano:")
                    print(f"   {summary[:200]}...")
                
            return True
            
        else:
            print(f"❌ Erro na requisição: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro: {e}")
        return False

def main():
    print("🏋️  TESTE DE TIPOS DE TREINO")
    print("="*50)
    
    # Teste 1: Treino em casa
    success_home = test_workout_generation(test_data_home, "TREINO EM CASA")
    
    # Teste 2: Treino na academia  
    success_gym = test_workout_generation(test_data_gym, "TREINO NA ACADEMIA")
    
    print("\n" + "="*50)
    print("📊 RESULTADOS:")
    print(f"   Treino em casa: {'✅ OK' if success_home else '❌ FALHA'}")
    print(f"   Treino na academia: {'✅ OK' if success_gym else '❌ FALHA'}")

if __name__ == "__main__":
    main()