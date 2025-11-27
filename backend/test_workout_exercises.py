#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Teste para verificar se o plano de treino gera 5-6 exercícios por dia
"""

import sys
import os
import json

# Adicionar o diretório app ao path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.ai_service import generate_workout_plan

def test_workout_exercises():
    print("🔥 Testando geração de plano de treino com 5-6 exercícios por dia...")
    
    # Dados do perfil do usuário (simulado)
    user_profile = {
        'name': 'Teste',
        'age': 30,
        'weight': 75,
        'height': 175,
        'gender': 'masculino'
    }
    
    # Dados do questionário (simulado)
    questionnaire_data = {
        'has_musculoskeletal_problems': False,
        'has_respiratory_problems': False, 
        'has_cardiac_problems': False,
        'previous_injuries': [],
        'fitness_level': 'intermediario',
        'preferred_exercises': ['flexoes', 'agachamentos'],
        'exercises_to_avoid': [],
        'workout_type': 'casa',
        'days_per_week': 3,
        'session_duration': 45,
        'available_days': ['Segunda', 'Quarta', 'Sexta']
    }
    
    try:
        # Gerar plano
        print("📊 Enviando dados para IA...")
        print(f"   - Perfil: {user_profile}")
        print(f"   - Questionário: {questionnaire_data}")
        
        result = generate_workout_plan(user_profile, questionnaire_data)
        
        print("✅ Resposta recebida da IA!")
        print(f"📝 Tamanho da resposta: {len(result)} caracteres")
        
        # Tentar fazer parse do JSON
        try:
            if isinstance(result, str):
                parsed_result = json.loads(result)
            else:
                parsed_result = result
                
            print("✅ JSON parseado com sucesso!")
            
            # Verificar estrutura
            if 'workout_schedule' in parsed_result:
                workout_schedule = parsed_result['workout_schedule']
                total_days = len(workout_schedule)
                
                print(f"📅 Número de dias criados: {total_days}")
                
                for i, day in enumerate(workout_schedule, 1):
                    day_name = day.get('day', f'Dia {i}')
                    exercises = day.get('exercises', [])
                    exercise_count = len(exercises)
                    
                    print(f"   {day_name}: {exercise_count} exercícios")
                    
                    if exercise_count < 5:
                        print(f"   ⚠️  PROBLEMA: Apenas {exercise_count} exercícios (deveria ser 5-6)")
                    elif exercise_count > 6:
                        print(f"   ⚠️  PROBLEMA: {exercise_count} exercícios (deveria ser 5-6)")
                    else:
                        print(f"   ✅ OK: {exercise_count} exercícios (dentro do esperado)")
                        
                    # Mostrar os exercícios
                    for j, exercise in enumerate(exercises, 1):
                        exercise_name = exercise.get('name', f'Exercício {j}')
                        print(f"      {j}. {exercise_name}")
                        
            else:
                print("❌ 'workout_schedule' não encontrado na resposta")
                print(f"🔍 Chaves disponíveis: {list(parsed_result.keys()) if isinstance(parsed_result, dict) else 'Não é dict'}")
                
        except json.JSONDecodeError as e:
            print(f"❌ Erro ao fazer parse do JSON: {e}")
            print("📄 Resposta bruta (primeiros 500 chars):")
            print(result[:500])
            
    except Exception as e:
        print(f"❌ Erro geral: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_workout_exercises()