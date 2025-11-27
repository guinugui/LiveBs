#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Teste completo: gera plano, salva no banco e verifica dados
"""

import sys
import os
import json
import pg8000.native
from uuid import uuid4

# Adicionar o diretório app ao path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.ai_service import generate_workout_plan
from app.database import db

def test_full_workout_flow():
    print("🔥 Teste completo: Backend -> Banco -> Verificação...")
    
    # Dados do teste
    user_profile = {
        'name': 'Teste Completo',
        'age': 25,
        'weight': 68,
        'height': 165,
        'gender': 'feminino'
    }
    
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
        print("📊 ETAPA 1: Gerando plano com IA...")
        
        # Gerar plano
        ai_result = generate_workout_plan(user_profile, questionnaire_data)
        
        # Parse do resultado
        if isinstance(ai_result, str):
            workout_plan = json.loads(ai_result)
        else:
            workout_plan = ai_result
            
        print(f"✅ Plano gerado pela IA")
        print(f"   📅 Dias: {len(workout_plan.get('workout_schedule', []))}")
        
        # Contar exercícios
        total_exercises = 0
        has_cardio = False
        
        for day in workout_plan.get('workout_schedule', []):
            exercises = day.get('exercises', [])
            day_exercises = len(exercises)
            total_exercises += day_exercises
            
            print(f"   🗓️  {day.get('day', 'N/A')}: {day_exercises} exercícios")
            
            # Verificar cardio
            for exercise in exercises:
                name = exercise.get('name', '').lower()
                if any(cardio_word in name for cardio_word in ['cardio', 'jumping', 'mountain', 'burpee', 'corrida', 'high knees']):
                    has_cardio = True
                    print(f"      🏃‍♀️ {exercise.get('name')} (CARDIO)")
                else:
                    print(f"      💪 {exercise.get('name')}")
        
        print(f"\n📈 RESUMO IA:")
        print(f"   📅 Total dias: {len(workout_plan.get('workout_schedule', []))}")
        print(f"   🏋️‍♀️ Total exercícios: {total_exercises}")
        print(f"   🏃‍♀️ Tem cardio: {'SIM' if has_cardio else 'NÃO'}")
        
        if not has_cardio:
            print("   ❌ PROBLEMA: Cardio não encontrado!")
            return False
        
        # ETAPA 2: Salvar no banco
        print("\n📊 ETAPA 2: Criando usuário de teste e salvando no banco...")
        
        # Simular usuário ID (UUID válido)
        test_user_id = "12345678-1234-5678-9abc-123456789abc"
        plan_id_uuid = str(uuid4())  # Gerar UUID para o plano
        plan_name = workout_plan.get('plan_name', 'Teste Plan')
        plan_summary = workout_plan.get('plan_summary', 'Teste Summary')
        
        with db.get_db_cursor() as cursor:
            # Verificar estrutura da tabela users primeiro
            cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'users'")
            columns = cursor.fetchall()
            if columns:
                try:
                    column_names = [col[0] if isinstance(col, tuple) else col['column_name'] for col in columns]
                    print(f"📋 Colunas da tabela users: {column_names}")
                except (KeyError, IndexError, TypeError):
                    print(f"📋 Colunas brutas: {columns}")
            else:
                print("📋 Nenhuma coluna encontrada na tabela users")
            
            # Criar usuário de teste primeiro
            cursor.execute("DELETE FROM users WHERE id = %s", (test_user_id,))
            cursor.execute(
                """INSERT INTO users (id, email, password_hash, created_at) 
                   VALUES (%s, %s, %s, NOW())""",
                (test_user_id, "teste@workout.com", "fake_hash")
            )
            print("✅ Usuário de teste criado")
            
            # Deletar planos de teste anteriores
            cursor.execute(
                "DELETE FROM saved_workout_plans WHERE user_id = %s",
                (test_user_id,)
            )
            
            # Inserir novo plano
            cursor.execute(
                   """INSERT INTO saved_workout_plans 
                      (id, user_id, plan_name, plan_summary, workout_data) 
                      VALUES (%s, %s, %s, %s, %s)""",
                (
                    plan_id_uuid,
                    test_user_id,
                    plan_name,
                    plan_summary,
                    json.dumps(workout_plan, ensure_ascii=False)
                )
            )
            
            # Verificar se foi salvo
            cursor.execute(
                "SELECT id, plan_name FROM saved_workout_plans WHERE id = %s",
                (plan_id_uuid,)
            )
            saved_result = cursor.fetchone()
            
            print(f"📊 Resultado da consulta: {saved_result}")
            print(f"📊 Tipo do resultado: {type(saved_result)}")
            
            if not saved_result:
                raise Exception("Erro: Plano não foi salvo no banco")
            
            # Em pg8000, fetchone() retorna uma lista, não um dicionário
            if isinstance(saved_result, (list, tuple)):
                plan_id = saved_result[0]  # ID é o primeiro campo
            else:
                plan_id = plan_id_uuid  # Fallback para o UUID criado
                
            print(f"✅ Plano salvo no banco - ID: {plan_id}")
        
        # ETAPA 3: Recuperar do banco e verificar
        print("\n📊 ETAPA 3: Recuperando do banco...")
        
        with db.get_db_cursor() as cursor:
            cursor.execute(
                """SELECT plan_name, plan_summary, workout_data 
                   FROM saved_workout_plans 
                   WHERE id = %s""",
                (plan_id,)
            )
            
            db_result = cursor.fetchone()
            
        if db_result:
            # Verificar tipo do resultado  
            print(f"📊 Resultado recuperado: {type(db_result)} - {len(db_result) if hasattr(db_result, '__len__') else 'N/A'} campos")
            
            db_plan_name = db_result['plan_name']  # plan_name
            db_plan_summary = db_result['plan_summary']  # plan_summary
            db_workout_data = db_result['workout_data']  # workout_data
            
            print(f"✅ Plano recuperado do banco")
            print(f"   📝 Nome: {db_plan_name}")
            
            # Parse do JSON do banco
            if isinstance(db_workout_data, str):
                db_workout_plan = json.loads(db_workout_data)
            else:
                db_workout_plan = db_workout_data
            
            # Verificar dados do banco
            db_schedule = db_workout_plan.get('workout_schedule', [])
            db_total_exercises = 0
            db_has_cardio = False
            
            print(f"\n📊 VERIFICAÇÃO BANCO:")
            print(f"   📅 Dias salvos: {len(db_schedule)}")
            
            for day in db_schedule:
                exercises = day.get('exercises', [])
                day_exercises = len(exercises)
                db_total_exercises += day_exercises
                
                print(f"   🗓️  {day.get('day', 'N/A')}: {day_exercises} exercícios")
                
                # Verificar cardio
                for exercise in exercises:
                    name = exercise.get('name', '').lower()
                    if any(cardio_word in name for cardio_word in ['cardio', 'jumping', 'mountain', 'burpee', 'corrida', 'high knees']):
                        db_has_cardio = True
            
            print(f"\n📈 RESUMO BANCO:")
            print(f"   📅 Total dias: {len(db_schedule)}")
            print(f"   🏋️‍♀️ Total exercícios: {db_total_exercises}")
            print(f"   🏃‍♀️ Tem cardio: {'SIM' if db_has_cardio else 'NÃO'}")
            
            # Comparar IA vs Banco
            if total_exercises == db_total_exercises and has_cardio == db_has_cardio:
                print(f"\n✅ SUCESSO: Dados consistentes entre IA e Banco!")
                return True
            else:
                print(f"\n❌ PROBLEMA: Inconsistência entre IA e Banco!")
                print(f"   IA: {total_exercises} exercícios, cardio: {has_cardio}")
                print(f"   Banco: {db_total_exercises} exercícios, cardio: {db_has_cardio}")
                return False
        
        else:
            print("❌ ERRO: Não foi possível recuperar dados do banco")
            return False
            
    except Exception as e:
        print(f"❌ ERRO: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_full_workout_flow()
    if success:
        print("\n🎉 TESTE COMPLETO: PASSOU!")
    else:
        print("\n💥 TESTE COMPLETO: FALHOU!")