#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Criar um novo plano de treino com as correções aplicadas
"""

import sys
import os
import json
from uuid import uuid4

# Adicionar o diretório app ao path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.database import db
from app.ai_service import generate_workout_plan

def create_new_test_plan():
    print("🔥 Criando um novo plano de treino com as correções...")
    
    # Dados do perfil do usuário (simulado)
    user_profile = {
        'name': 'Teste Novo',
        'age': 30,
        'weight': 75,
        'height': 175,
        'gender': 'masculino'
    }
    
    # Dados do questionário - 5 DIAS + CARDIO
    questionnaire_data = {
        'has_musculoskeletal_problems': False,
        'has_respiratory_problems': False, 
        'has_cardiac_problems': False,
        'previous_injuries': [],
        'fitness_level': 'intermediario',
        'preferred_exercises': ['cardio', 'agachamentos', 'flexoes'],
        'exercises_to_avoid': [],
        'workout_type': 'casa',
        'days_per_week': 5,
        'session_duration': 60,
        'available_days': ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta']
    }
    
    try:
        print("📊 Gerando plano com IA corrigida...")
        ai_result = generate_workout_plan(user_profile, questionnaire_data)
        
        # Parse do resultado
        if isinstance(ai_result, str):
            workout_plan = json.loads(ai_result)
        else:
            workout_plan = ai_result
            
        print(f"✅ IA gerou plano com sucesso")
        print(f"   📝 Nome: {workout_plan.get('plan_name', 'Sem nome')}")
        
        workout_schedule = workout_plan.get('workout_schedule', [])
        print(f"   📅 Dias: {len(workout_schedule)}")
        
        total_exercises = 0
        for day in workout_schedule:
            exercises = day.get('exercises', [])
            day_name = day.get('day', 'Sem nome')
            exercise_count = len(exercises)
            total_exercises += exercise_count
            print(f"   🗓️  {day_name}: {exercise_count} exercícios")
        
        print(f"   🏋️‍♀️ Total de exercícios: {total_exercises}")
        
        # Usar um usuário existente (pegar o primeiro)
        with db.get_db_cursor() as cursor:
            cursor.execute("SELECT id FROM users LIMIT 1")
            user_result = cursor.fetchone()
            
            if not user_result:
                print("❌ Nenhum usuário encontrado. Execute um teste completo primeiro.")
                return
                
            user_id = user_result['id']
            print(f"📋 Usando usuário: {user_id}")
        
        # Salvar no banco
        plan_id = str(uuid4())
        with db.get_db_cursor() as cursor:
            cursor.execute(
                """INSERT INTO saved_workout_plans 
                   (id, user_id, plan_name, plan_summary, workout_data) 
                   VALUES (%s, %s, %s, %s, %s)""",
                (
                    plan_id,
                    user_id,
                    workout_plan['plan_name'],
                    workout_plan.get('plan_summary', ''),
                    json.dumps(workout_plan, ensure_ascii=False)
                )
            )
        
        print(f"✅ Plano salvo com ID: {plan_id}")
        
        # Verificar se foi salvo corretamente
        with db.get_db_cursor() as cursor:
            cursor.execute(
                """SELECT plan_name, workout_data FROM saved_workout_plans 
                   WHERE id = %s""",
                (plan_id,)
            )
            saved_plan = cursor.fetchone()
            
        if saved_plan:
            saved_data = saved_plan['workout_data']
            if isinstance(saved_data, dict):
                saved_schedule = saved_data.get('workout_schedule', [])
                saved_total = sum(len(day.get('exercises', [])) for day in saved_schedule)
                print(f"✅ Verificação banco: {len(saved_schedule)} dias, {saved_total} exercícios totais")
            else:
                print(f"⚠️  Dados salvos como string: {type(saved_data)}")
                
        print(f"\n🎉 TESTE CONCLUÍDO! Use o plano ID: {plan_id} no Flutter")
        
    except Exception as e:
        print(f"❌ Erro: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    print("🚀 Criando novo plano de teste com 5-6 exercícios...")
    create_new_test_plan()
    
    create_new_test_plan()