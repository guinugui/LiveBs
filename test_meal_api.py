import requests
import json

print("=== TESTANDO API DO NUTRI AI ===")

try:
    # Login primeiro
    login_data = {'email': 'gui@gmail.com', 'password': '123123'}
    login_response = requests.post('http://localhost:8001/auth/login', json=login_data)
    print(f'Login: {login_response.status_code}')

    if login_response.status_code == 200:
        token = login_response.json()['access_token']
        headers = {'Authorization': f'Bearer {token}'}
        
        print("✅ Login realizado com sucesso!")
        
        # Criar plano alimentar
        print("\n=== CRIANDO PLANO ALIMENTAR ===")
        meal_response = requests.post('http://localhost:8001/meal-plan', headers=headers)
        print(f'Meal Plan: {meal_response.status_code}')
        
        if meal_response.status_code == 200:
            plan = meal_response.json()
            print('✅ Plano criado com sucesso!')
            print(f'Nome: {plan.get("name", "Sem nome")}')
            
            # Verificar estrutura do plano gerado
            generated_plan = plan.get('generated_plan', {})
            if 'days' in generated_plan and len(generated_plan['days']) > 0:
                day = generated_plan['days'][0]
                meals = day.get('meals', [])
                print(f'📊 Total de refeições: {len(meals)}')
                
                print("\n=== ANÁLISE ANTI-REPETIÇÃO ===")
                # Mostrar todas as refeições
                for meal_idx, meal in enumerate(meals):
                    meal_name = meal.get('name', 'Sem nome')
                    foods = meal.get('foods', [])
                    print(f'\n{meal_idx+1}. {meal_name} ({len(foods)} alimentos):')
                    
                    # Mostrar todos os alimentos
                    for i, food in enumerate(foods):
                        name = food.get('name', 'Sem nome')
                        quantity = food.get('quantity', 'Sem medida')
                        print(f'   {i+1}. {name} - {quantity}')
            else:
                print('❌ Estrutura do plano inválida')
                print(f'Estrutura recebida: {generated_plan}')
        else:
            print('❌ Erro ao criar plano:', meal_response.text)
    else:
        print('❌ Login falhou:', login_response.text)

except Exception as e:
    print(f'❌ Erro geral: {e}')