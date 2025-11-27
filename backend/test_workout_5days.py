#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Teste específico para plano de treino de 5 dias com cardio
"""

import sys
import os
import json

# Adicionar o diretório app ao path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.ai_service import generate_workout_plan

def test_workout_5_days_with_cardio():
    print("🔥 Testando geração de plano de treino - 5 DIAS com CARDIO...")
    
    # Dados do perfil do usuário (simulado)
    user_profile = {
        'name': 'Teste 5 Dias',
        'age': 28,
        'weight': 70,
        'height': 170,
        'gender': 'feminino'
    }
    
    # Dados do questionário - EXIGINDO 5 DIAS
    questionnaire_data = {
        'has_musculoskeletal_problems': False,
        'has_respiratory_problems': False, 
        'has_cardiac_problems': False,
        'previous_injuries': [],
        'fitness_level': 'intermediario',
        'preferred_exercises': ['cardio', 'agachamentos', 'flexoes'],
        'exercises_to_avoid': [],
        'workout_type': 'casa',
        'days_per_week': 5,  # <<<< EXIGINDO 5 DIAS
        'session_duration': 60,
        'available_days': ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta']
    }
    
    try:
        print(f"🎯 TESTE ESPECÍFICO:")
        print(f"   ✅ Dias solicitados: {questionnaire_data['days_per_week']}")
        print(f"   ✅ Exercícios preferidos: {questionnaire_data['preferred_exercises']}")
        print(f"   ✅ Duração: {questionnaire_data['session_duration']} minutos")
        
        # Gerar plano
        result = generate_workout_plan(user_profile, questionnaire_data)
        
        print("\n📋 RESULTADO:")
        
        # Parse do JSON
        if isinstance(result, str):
            parsed_result = json.loads(result)
        else:
            parsed_result = result
            
        # Verificar estrutura
        if 'workout_schedule' in parsed_result:
            workout_schedule = parsed_result['workout_schedule']
            total_days = len(workout_schedule)
            
            print(f"📅 Dias criados: {total_days} (solicitado: {questionnaire_data['days_per_week']})")
            
            if total_days != questionnaire_data['days_per_week']:
                print(f"❌ PROBLEMA: Esperava {questionnaire_data['days_per_week']} dias, mas recebeu {total_days}")
            else:
                print(f"✅ OK: Número correto de dias")
            
            # Analisar cada dia
            total_exercises = 0
            has_cardio = False
            
            for i, day in enumerate(workout_schedule, 1):
                day_name = day.get('day', f'Dia {i}')
                focus = day.get('focus', 'Sem foco definido')
                exercises = day.get('exercises', [])
                exercise_count = len(exercises)
                total_exercises += exercise_count
                
                print(f"\n🗓️  {day_name} - {focus}")
                print(f"   📊 {exercise_count} exercícios:")
                
                for j, exercise in enumerate(exercises, 1):
                    exercise_name = exercise.get('name', f'Exercício {j}')
                    sets = exercise.get('sets', 'N/A')
                    reps = exercise.get('reps', 'N/A')
                    
                    # Verificar se tem cardio
                    if 'cardio' in exercise_name.lower() or 'corrida' in exercise_name.lower() or 'caminhada' in exercise_name.lower():
                        has_cardio = True
                        print(f"      {j}. {exercise_name} ({sets} séries, {reps}) 🏃‍♀️ CARDIO")
                    else:
                        print(f"      {j}. {exercise_name} ({sets} séries, {reps})")
                
                # Verificar quantidade de exercícios por dia
                if exercise_count < 5:
                    print(f"   ⚠️  PROBLEMA: Apenas {exercise_count} exercícios (deveria ser 5-6)")
                elif exercise_count > 6:
                    print(f"   ⚠️  PROBLEMA: {exercise_count} exercícios (deveria ser 5-6)")
                else:
                    print(f"   ✅ OK: {exercise_count} exercícios")
            
            print(f"\n📈 RESUMO FINAL:")
            print(f"   📅 Total de dias: {total_days}")
            print(f"   🏋️‍♀️ Total de exercícios: {total_exercises}")
            print(f"   🏃‍♀️ Tem cardio: {'SIM' if has_cardio else 'NÃO'}")
            print(f"   📊 Média por dia: {total_exercises/total_days:.1f} exercícios")
            
            if not has_cardio:
                print(f"   ❌ PROBLEMA: Cardio foi solicitado mas não aparece no plano!")
                
        else:
            print("❌ 'workout_schedule' não encontrado na resposta")
            
        # Salvar resultado completo para análise
        with open('workout_5days_result.json', 'w', encoding='utf-8') as f:
            if isinstance(result, str):
                f.write(result)
            else:
                json.dump(result, f, ensure_ascii=False, indent=2)
        print(f"\n💾 Resultado completo salvo em: workout_5days_result.json")
            
    except Exception as e:
        print(f"❌ Erro: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_workout_5_days_with_cardio()