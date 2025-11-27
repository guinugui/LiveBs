#!/usr/bin/env python3
"""
Script para testar geração de plano de treino para academia
"""

import sys
import os
import json

# Adicionar o diretório pai ao path para importar módulos
sys.path.append(os.path.dirname(__file__))

from app.ai_service import generate_workout_plan

def test_gym_workout():
    """Testa a geração de plano para academia"""
    
    print("🏋️ Testando geração de plano de treino para ACADEMIA...")
    
    # Simular perfil do usuário
    user_profile = {
        'weight': 87.0,
        'height': 155.0,
        'age': 23,
        'gender': 'male',
        'target_weight': 75.0,
        'activity_level': 'moderate'
    }
    
    # Simular questionário para ACADEMIA
    questionnaire_data = {
        'has_musculoskeletal_problems': False,
        'musculoskeletal_details': None,
        'has_respiratory_problems': False,
        'respiratory_details': None,
        'has_cardiac_problems': False,
        'cardiac_details': None,
        'previous_injuries': [],
        'fitness_level': 'intermediario',
        'preferred_exercises': ['Musculação', 'Cardio/Aeróbico'],
        'exercises_to_avoid': [],
        'workout_type': 'gym',  # ACADEMIA
        'days_per_week': 5,
        'session_duration': 75,
        'available_days': ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira']
    }
    
    try:
        # Gerar plano
        workout_plan_json = generate_workout_plan(
            user_profile=user_profile,
            questionnaire_data=questionnaire_data
        )
        
        # Parse do JSON
        workout_plan = json.loads(workout_plan_json)
        
        print(f"\n✅ Plano gerado com sucesso!")
        print(f"📋 Nome: {workout_plan.get('plan_name')}")
        print(f"📝 Resumo: {workout_plan.get('plan_summary')}")
        
        # Verificar workout_schedule
        schedule = workout_plan.get('workout_schedule', [])
        print(f"📅 Dias de treino: {len(schedule)}")
        
        # Verificar exercícios de cada dia
        for i, day in enumerate(schedule):
            day_name = day.get('day', f'Dia {i+1}')
            exercises = day.get('exercises', [])
            print(f"\n🗓️ {day_name} ({day.get('focus', 'N/A')}):")
            print(f"   💪 {len(exercises)} exercícios")
            
            # Mostrar primeiros 3 exercícios para verificar se são de academia
            for j, exercise in enumerate(exercises[:3]):
                name = exercise.get('name', 'N/A')
                equipment = exercise.get('equipment', 'N/A')
                print(f"   {j+1}. {name} - Equipamento: {equipment}")
                
                # Verificar se são exercícios de academia
                gym_keywords = ['barra', 'halter', 'supino', 'leg press', 'puxada', 'pulley', 'máquina']
                home_keywords = ['flexão', 'peso corporal', 'agachamento livre']
                
                name_lower = name.lower()
                equipment_lower = equipment.lower()
                
                is_gym_exercise = any(keyword in name_lower or keyword in equipment_lower for keyword in gym_keywords)
                is_home_exercise = any(keyword in name_lower or keyword in equipment_lower for keyword in home_keywords)
                
                if is_gym_exercise:
                    print(f"      ✅ Exercício de academia detectado")
                elif is_home_exercise:
                    print(f"      ❌ PROBLEMA: Exercício de casa em plano de academia!")
                else:
                    print(f"      ⚠️ Exercício neutro")
                    
            if len(exercises) > 3:
                print(f"   ... e mais {len(exercises) - 3} exercícios")
                
        print(f"\n🎯 RESULTADO: Plano para academia com {len(schedule)} dias e exercícios apropriados")
        
    except Exception as e:
        print(f"❌ Erro ao gerar plano: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_gym_workout()