#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script para verificar os dados exatos que estão salvos no banco
"""

import sys
import os
import json

# Adicionar o diretório app ao path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.database import db

def check_saved_workout_data():
    print("🔍 Verificando dados salvos no banco...")
    
    try:
        with db.get_db_cursor() as cursor:
            # Buscar o plano mais recente
            cursor.execute(
                """SELECT id, plan_name, plan_summary, workout_data, created_at
                   FROM saved_workout_plans 
                   ORDER BY created_at DESC 
                   LIMIT 1"""
            )
            result = cursor.fetchone()
            
            if result:
                print(f"📋 Plano encontrado:")
                print(f"   ID: {result['id']}")
                print(f"   Nome: {result['plan_name']}")
                print(f"   Resumo: {result['plan_summary']}")
                print(f"   Criado em: {result['created_at']}")
                print(f"   Tamanho dos dados: {len(result['workout_data'])} chars")
                
                # Analisar os dados do workout
                workout_data = result['workout_data']
                print(f"\n📊 PRIMEIROS 500 CARACTERES:")
                try:
                    # workout_data pode ser string ou dict
                    if isinstance(workout_data, str):
                        print(workout_data[:500])
                        print(f"\n📊 ÚLTIMOS 500 CARACTERES:")
                        print(workout_data[-500:])
                    else:
                        print(f"📊 Tipo dos dados: {type(workout_data)}")
                        print(f"📊 Dados completos: {workout_data}")
                except Exception as e:
                    print(f"❌ Erro: {e}")
                    print(f"📊 Tipo dos dados: {type(workout_data)}")
                    print(f"📊 Dados completos: {workout_data}")
                
                # Verificar se já é dicionário ou string
                if isinstance(workout_data, dict):
                    print(f"\n✅ DADOS JÁ SÃO DICIONÁRIO (PostgreSQL fez parse automático)")
                    parsed = workout_data
                else:
                    # Tentar fazer parse do JSON string
                    try:
                        parsed = json.loads(workout_data)
                        print(f"\n✅ JSON PARSEADO COM SUCESSO!")
                    except Exception as e:
                        print(f"\n❌ Erro no parse JSON: {e}")
                        return
                    
                print(f"   Chaves: {list(parsed.keys())}")
                
                if 'workout_schedule' in parsed:
                    schedule = parsed['workout_schedule']
                    print(f"   Dias no cronograma: {len(schedule)}")
                    
                    for i, day in enumerate(schedule):
                        day_name = day.get('day', f'Dia {i+1}')
                        exercises = day.get('exercises', [])
                        print(f"     {day_name}: {len(exercises)} exercícios")
                        
                        for j, exercise in enumerate(exercises):
                            print(f"       {j+1}. {exercise.get('name', 'Sem nome')}")
                else:
                    print(f"   ❌ 'workout_schedule' não encontrado!")
                    print(f"   📋 Chaves disponíveis: {list(parsed.keys())}")
                    
                    # Salvar dados para análise
                    with open('debug_workout_data.txt', 'w', encoding='utf-8') as f:
                        f.write("=== DADOS SEM workout_schedule ===\n")
                        f.write(f"ID: {result['id']}\n")
                        f.write(f"Nome: {result['plan_name']}\n")
                        f.write(f"Chaves: {list(parsed.keys())}\n\n")
                        f.write("=== DADOS COMPLETOS ===\n")
                        f.write(str(parsed))
                    
                    print(f"💾 Dados salvos em debug_workout_data.txt para análise")
                    
            else:
                print("❌ Nenhum plano encontrado no banco")
                
    except Exception as e:
        print(f"❌ Erro: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    check_saved_workout_data()