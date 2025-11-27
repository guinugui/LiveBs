#!/usr/bin/env python3
"""
Script para debug do formato dos dados de workout no banco
"""

import sys
import os
import json

# Adicionar o diretório pai ao path para importar módulos
sys.path.append(os.path.dirname(__file__))

from app import database

# Instanciar o database
db = database.Database()

def check_workout_data_format():
    """Verifica o formato dos dados de workout no banco"""
    
    print("🔍 Verificando formato dos dados de workout no banco...")
    
    try:
        with db.get_db_cursor() as cursor:
            # Buscar planos mais recentes
            cursor.execute(
                """SELECT id, plan_name, workout_data, created_at 
                   FROM saved_workout_plans 
                   ORDER BY created_at DESC 
                   LIMIT 3"""
            )
            plans = cursor.fetchall()
            
            if not plans:
                print("❌ Nenhum plano encontrado no banco")
                return
                
            for i, plan in enumerate(plans):
                print(f"\n📋 PLANO {i + 1}:")
                print(f"  ID: {plan.get('id')}")
                print(f"  Nome: {plan.get('plan_name')}")
                print(f"  Criado: {plan.get('created_at')}")
                
                workout_data = plan.get('workout_data')
                if workout_data:
                    print(f"  Tipo dos dados: {type(workout_data)}")
                    
                    if isinstance(workout_data, str):
                        print(f"  Tamanho: {len(workout_data)} chars")
                        print(f"  Primeiros 300 chars: {workout_data[:300]}")
                        print(f"  Últimos 100 chars: {workout_data[-100:]}")
                        
                        # Tentar fazer parse JSON
                        try:
                            parsed = json.loads(workout_data)
                            print(f"  ✅ JSON válido!")
                            
                            if 'workout_schedule' in parsed:
                                schedule = parsed['workout_schedule']
                                print(f"  📅 Workout Schedule: {len(schedule)} dias")
                                
                                for j, day in enumerate(schedule):
                                    if isinstance(day, dict) and 'day' in day and 'exercises' in day:
                                        exercises = day['exercises']
                                        print(f"    Dia {j+1} ({day['day']}): {len(exercises)} exercícios")
                                    else:
                                        print(f"    Dia {j+1}: Formato inválido - {type(day)}")
                            else:
                                print(f"  ❌ workout_schedule não encontrado")
                                
                        except json.JSONDecodeError as e:
                            print(f"  ❌ Erro no JSON: {e}")
                            # Tentar identificar o problema
                            try:
                                # Verificar se é formato PostgreSQL
                                if workout_data.startswith('{') and not workout_data.startswith('{"'):
                                    print(f"  🔧 Parece ser formato PostgreSQL (sem aspas)")
                            except:
                                pass
                                
                    elif isinstance(workout_data, dict):
                        print(f"  📊 Dict com {len(workout_data)} chaves: {list(workout_data.keys())}")
                        if 'workout_schedule' in workout_data:
                            schedule = workout_data['workout_schedule']
                            print(f"  📅 Workout Schedule: {len(schedule)} dias")
                    else:
                        print(f"  ⚠️ Tipo inesperado: {type(workout_data)}")
                else:
                    print(f"  ❌ workout_data é None ou vazio")
                    
    except Exception as e:
        print(f"❌ Erro ao verificar dados: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    check_workout_data_format()