from openai import OpenAI
from app.config import settings
import json

client = OpenAI(api_key=settings.openai_api_key)

def get_ai_response(messages: list[dict], user_profile: dict = None) -> str:
    """
    Obtém resposta do nutricionista IA

    Args:
        messages: Lista de mensagens no formato [{"role": "user", "content": "..."}]
        user_profile: Dados do perfil do usuário (peso, altura, objetivo, etc)

    Returns:
        Resposta do assistente IA
    """
    system_prompt = """Você é Dr. Nutri, um nutricionista virtual especializado em
    emagrecimento saudável. Você é gentil, motivador e baseado em evidências científicas.
    Sempre considere o perfil do usuário ao dar recomendações."""

    if user_profile:
        system_prompt += f"""

        Perfil do usuário:
        - Peso atual: {user_profile.get('weight')} kg
        - Altura: {user_profile.get('height')} cm
        - Idade: {user_profile.get('age')} anos
        - Peso alvo: {user_profile.get('target_weight')} kg
        - Nível de atividade: {user_profile.get('activity_level')}
        - Calorias diárias: {user_profile.get('daily_calories')} kcal
        """

        if user_profile.get('dietary_restrictions'):
            system_prompt += f"\n- Restrições alimentares: {', '.join(user_profile['dietary_restrictions'])}"

        if user_profile.get('dietary_preferences'):
            system_prompt += f"\n- Preferências: {', '.join(user_profile['dietary_preferences'])}"

    all_messages = [{"role": "system", "content": system_prompt}] + messages

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=all_messages,
        temperature=0.7,
        max_tokens=2000
    )

    return response.choices[0].message.content


def generate_meal_plan(user_profile: dict) -> dict:
    """
    Gera plano alimentar de 3 dias personalizado
    
    Args:
        user_profile: Dados do usuário incluindo calorias, restrições, preferências
        
    Returns:
        Dicionário com plano de 3 dias
    """
    
    # Extrair dados do perfil
    calories = user_profile.get('daily_calories', 1800)
    weight = user_profile.get('weight', 70)
    height = user_profile.get('height', 170)
    age = user_profile.get('age', 30)
    target_weight = user_profile.get('target_weight', 65)
    activity_level = user_profile.get('activity_level', 'moderado')
    restrictions = user_profile.get('dietary_restrictions', [])
    preferences = user_profile.get('dietary_preferences', [])
    
    # Determinar objetivo baseado no peso atual vs peso alvo
    if target_weight < weight:
        objetivo = "EMAGRECER"
        objetivo_text = f"deficit calórico para perder {weight - target_weight:.1f}kg"
    elif target_weight > weight:
        objetivo = "GANHAR PESO"
        objetivo_text = f"superavit calórico para ganhar {target_weight - weight:.1f}kg"
    else:
        objetivo = "MANTER PESO"
        objetivo_text = "manutenção do peso atual"
    
    # Construir informações de restrições
    restriction_text = ""
    if restrictions:
        restriction_text = f"EVITE: {', '.join(restrictions)}"
    
    preference_text = ""
    if preferences:
        preference_text = f"PRIORIZE: {', '.join(preferences)}"

    prompt = f"""Crie um PLANO MODELO personalizado para 7 dias com grupos alimentares didáticos e comidas brasileiras comuns.

PERFIL DO CLIENTE:
- Peso atual: {weight}kg
- Altura: {height}cm  
- Idade: {age} anos
- Peso alvo: {target_weight}kg
- Objetivo: {objetivo} ({objetivo_text})
- Nível de atividade: {activity_level}
- Calorias diárias recomendadas: {calories} kcal
- Restrições: {restriction_text if restriction_text else "Nenhuma"}
- Preferências: {preference_text if preference_text else "Nenhuma"}

IMPORTANTE: Ajuste as porções e alimentos baseado no OBJETIVO do cliente ({objetivo}):

MODELO POR REFEIÇÃO PERSONALIZADA (mesmo padrão todos os 7 dias):

CAFÉ DA MANHÃ ({int(calories * 0.2)}-{int(calories * 0.25)} kcal):
- Carboidratos: {"porções menores" if objetivo == "EMAGRECER" else "porções normais" if objetivo == "MANTER PESO" else "porções maiores"}: arroz doce, pão francês, tapioca, aveia, biscoito integral, banana
- Proteínas (PRIORIDADE para {objetivo}): ovos, leite, iogurte natural, queijo minas, requeijão
- Gorduras boas: {"1 col" if objetivo == "EMAGRECER" else "1-2 col"}: azeite, manteiga, castanhas, amendoim
- Frutas: banana, maçã, mamão, laranja, melancia

ALMOÇO ({int(calories * 0.35)}-{int(calories * 0.4)} kcal):
- Carboidratos: {"porções reduzidas" if objetivo == "EMAGRECER" else "porções normais" if objetivo == "MANTER PESO" else "porções aumentadas"}: arroz branco, feijão carioca, batata, macarrão, farinha de mandioca
- Proteínas (ESSENCIAL para {objetivo}): frango grelhado, carne de panela, peixe, ovo cozido
- Gorduras boas: {"1 col" if objetivo == "EMAGRECER" else "1-2 col"}: óleo de soja, azeite de oliva
- Verduras/Legumes (À VONTADE - especialmente para emagrecimento): alface, tomate, cenoura, abobrinha, chuchu, repolho

LANCHE ({int(calories * 0.1)}-{int(calories * 0.15)} kcal):
- Carboidratos: {"evitar se emagrecer" if objetivo == "EMAGRECER" else "moderado"}: biscoito água e sal, pão de forma, fruta
- Proteínas (IMPORTANTE): queijo, iogurte, leite
- Gorduras: {"evitar" if objetivo == "EMAGRECER" else "1 col"}: castanhas, amendoim

JANTAR ({int(calories * 0.25)}-{int(calories * 0.3)} kcal):
- Carboidratos: {"REDUZIR para emagrecimento" if objetivo == "EMAGRECER" else "porções normais"}: arroz, batata cozida, macarrão, pão
- Proteínas (PRIORIDADE no jantar): frango desfiado, ovo, queijo, sardinha
- Gorduras: {"mínimo" if objetivo == "EMAGRECER" else "1 col"}: azeite, óleo
- Verduras/Legumes (AUMENTAR à vontade): salada verde, sopa de legumes, abobrinha refogada

ESTRUTURA JSON:
{{"day":1,"meals":[{{"type":"breakfast","carbs_foods":["arroz doce","pão francês","tapioca","aveia","biscoito integral","banana"],"protein_foods":["ovos","leite","iogurte natural","queijo minas"],"fat_foods":["azeite","manteiga","castanhas","amendoim"],"vegetables":["banana","maçã","mamão","laranja"]}},{{"type":"lunch","carbs_foods":["arroz branco","feijão carioca","batata","macarrão"],"protein_foods":["frango grelhado","carne de panela","peixe","ovo cozido"],"fat_foods":["óleo de soja","azeite"],"vegetables":["alface","tomate","cenoura","abobrinha","chuchu"]}},{{"type":"afternoon_snack","carbs_foods":["biscoito água e sal","pão de forma","fruta"],"protein_foods":["queijo","iogurte","leite"],"fat_foods":["castanhas","amendoim"],"vegetables":[]}},{{"type":"dinner","carbs_foods":["arroz","batata cozida","macarrão","pão"],"protein_foods":["frango desfiado","ovo","queijo","sardinha"],"fat_foods":["azeite","óleo"],"vegetables":["salada verde","sopa de legumes","abobrinha refogada"]}}]}}

REGRAS IMPORTANTES PERSONALIZADAS:
- Use APENAS alimentos brasileiros comuns (arroz, feijão, frango, etc)
- {restriction_text}
- {preference_text}
- OBJETIVO {objetivo}: {"Foque em proteínas e verduras, reduza carboidratos" if objetivo == "EMAGRECER" else "Equilibre todos os grupos" if objetivo == "MANTER PESO" else "Aumente porções de todos os grupos, especialmente carboidratos"}
- ATIVIDADE {activity_level}: {"Mais carboidratos pré e pós treino" if activity_level in ["alto", "muito alto"] else "Carboidratos moderados"}
- IDADE {age} anos: {"Metabolismo mais lento, porções menores" if age > 50 else "Metabolismo normal"}
- Separe por grupos: carbs_foods, protein_foods, fat_foods, vegetables  
- Alimentos específicos, não receitas
- Variedade em cada grupo para escolha do usuário
- Ajuste as quantidades de alimentos baseado no perfil: peso {weight}kg → {target_weight}kg

Retorne APENAS o JSON de 1 dia modelo personalizado, sem explicações."""

    print(f"[DEBUG] Chamando OpenAI com prompt de {len(prompt)} chars")
    
    try:
    
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=4000
        )
        
        print(f"[DEBUG] OpenAI respondeu com sucesso")
        
        import json
        import re
        
        # Pega a resposta
        content = response.choices[0].message.content
        print(f"[DEBUG] Content length: {len(content)}")
        
        # Remove possíveis markdown ou texto extra
        content = re.sub(r'^```json\s*', '', content)
        content = re.sub(r'\s*```$', '', content)
        content = content.strip()
        
        # Tenta fazer parse
        try:
            result = json.loads(content)
            print(f"[DEBUG] JSON parseado com sucesso. Keys: {list(result.keys()) if isinstance(result, dict) else 'Not dict'}")
            
            # Converter para estrutura esperada (compatibilidade com sistema antigo)
            if 'day' in result and 'meals' in result:
                # Nova estrutura: transforma em formato antigo com array de dias
                compatible_result = {
                    "days": [result]  # Coloca o dia único dentro do array esperado
                }
                print(f"[DEBUG] Convertido para estrutura compatível com {len(compatible_result['days'])} dia(s)")
                return compatible_result
            
            return result
        except json.JSONDecodeError as e:
            print(f"[DEBUG] Erro ao parsear JSON: {e}")
            # Se falhar, salva para debug
            with open('error_response.txt', 'w', encoding='utf-8') as f:
                f.write(f"ERRO: {e}\n\n")
                f.write(f"POSIÇÃO: linha {e.lineno}, coluna {e.colno}, char {e.pos}\n\n")
                f.write("RESPOSTA:\n")
                f.write(content)
            raise Exception(f"Erro ao parsear JSON da OpenAI. Detalhes salvos em error_response.txt: {e}")
            
    except Exception as e:
        print(f"[DEBUG] Erro geral na chamada OpenAI: {e}")
        raise


def generate_workout_plan(questionnaire_data: dict) -> dict:
    """
    Gera plano de treino personalizado baseado no questionário
    
    Args:
        questionnaire_data: Dados do questionário incluindo problemas de saúde, tipo de treino, etc.
        
    Returns:
        Dicionário com plano de treino personalizado
    """
    
    # Extrair dados do questionário
    health_problems = questionnaire_data.get('healthProblems', {})
    injury_history = questionnaire_data.get('injuryHistory', {})
    fitness_level = questionnaire_data.get('fitnessLevel', 'iniciante')
    exercise_preferences = questionnaire_data.get('exercisePreferences', [])
    workout_type = questionnaire_data.get('workoutType', 'casa')
    days_per_week = questionnaire_data.get('daysPerWeek', 3)
    selected_days = questionnaire_data.get('selectedDays', [])
    
    # Processar problemas de saúde
    health_issues = []
    if health_problems.get('muscular', False):
        if health_problems.get('muscularDetails'):
            health_issues.append(f"Problemas musculares: {health_problems.get('muscularDetails')}")
        else:
            health_issues.append("Problemas musculares")
    if health_problems.get('respiratory', False):
        if health_problems.get('respiratoryDetails'):
            health_issues.append(f"Problemas respiratórios: {health_problems.get('respiratoryDetails')}")
        else:
            health_issues.append("Problemas respiratórios")
    if health_problems.get('cardiac', False):
        if health_problems.get('cardiacDetails'):
            health_issues.append(f"Problemas cardíacos: {health_problems.get('cardiacDetails')}")
        else:
            health_issues.append("Problemas cardíacos")
    if health_problems.get('joint', False):
        if health_problems.get('jointDetails'):
            health_issues.append(f"Problemas articulares: {health_problems.get('jointDetails')}")
        else:
            health_issues.append("Problemas articulares")
    
    # Processar lesões
    injuries = []
    if injury_history.get('hasInjuries', False) and injury_history.get('injuryDetails'):
        injuries.append(injury_history.get('injuryDetails'))
    
    # Definir equipamentos baseado no tipo de treino
    equipment_available = "academia completa com todos os equipamentos" if workout_type == 'academia' else "apenas o peso corporal (sem equipamentos)"
    
    health_text = "Nenhum problema de saúde relatado" if not health_issues else "; ".join(health_issues)
    injury_text = "Nenhuma lesão relatada" if not injuries else "; ".join(injuries)
    preferences_text = "Nenhuma preferência específica" if not exercise_preferences else ", ".join(exercise_preferences)
    
    # Ajustar intensidade baseado no nível
    intensity_guide = {
        'iniciante': "exercícios básicos, baixa intensidade, foco na técnica correta",
        'intermediario': "exercícios moderados, intensidade média, progressão gradual",
        'avancado': "exercícios desafiadores, alta intensidade, variações avançadas"
    }
    
    workout_location = "em casa" if workout_type == 'casa' else "na academia"
    
    prompt = f"""Crie um PLANO DE TREINO personalizado para {days_per_week} dias por semana ({workout_location}).

PERFIL DO CLIENTE:
- Nível de condicionamento: {fitness_level} ({intensity_guide.get(fitness_level, "moderado")})
- Problemas de saúde: {health_text}
- Histórico de lesões: {injury_text}
- Preferências de exercícios: {preferences_text}
- Local de treino: {workout_type}
- Equipamentos disponíveis: {equipment_available}
- Frequência: {days_per_week} dias por semana
- Dias da semana: {', '.join(selected_days) if selected_days else 'Não especificado'}

DIRETRIZES IMPORTANTES:
- SEMPRE considere os problemas de saúde e lesões para EVITAR exercícios contraindicados
- Para problemas cardíacos/respiratórios: exercícios de baixa intensidade, monitoramento constante
- Para problemas articulares: evitar impacto, priorizar mobilidade e fortalecimento
- Para lesões: modificações específicas ou exercícios alternativos
- Nível {fitness_level}: {intensity_guide.get(fitness_level, "moderado")}

ESTRUTURA DO TREINO:
- Aquecimento (5-10 min): preparação do corpo
- Treino principal (20-40 min): exercícios específicos por grupo muscular
- Alongamento (5-10 min): relaxamento e flexibilidade

{"TREINO EM CASA (sem equipamentos):" if workout_type == 'casa' else "TREINO NA ACADEMIA:"}
{"- Use apenas peso corporal, exercícios funcionais" if workout_type == 'casa' else "- Use equipamentos disponíveis: halteres, barras, máquinas, etc."}
{"- Foque em: flexões, agachamentos, pranchas, burpees, etc." if workout_type == 'casa' else "- Foque em: exercícios compostos e isolados com equipamentos"}

FORMATO JSON OBRIGATÓRIO:
{{"workout_type":"{workout_type}","days_per_week":{days_per_week},"fitness_level":"{fitness_level}","health_considerations":"{health_text}","workout_days":[{{"day_name":"Dia 1","muscle_groups":["peitoral","tríceps"],"exercises":[{{"name":"Flexão de braço","sets":3,"reps":"8-12","rest":"60s","instructions":"Mantenha o corpo reto, desça até quase tocar o peito no chão","modifications":"Se necessário, apoie os joelhos"}},{{"name":"Flexão diamante","sets":2,"reps":"5-8","rest":"60s","instructions":"Forme um diamante com as mãos, foque no tríceps","modifications":"Versão mais fácil: flexão normal"}}],"warm_up":[{{"name":"Rotação de braços","duration":"30s","instructions":"Movimentos circulares com os braços"}},{{"name":"Alongamento dinâmico","duration":"1min","instructions":"Movimentos suaves para aquecer"}}],"cool_down":[{{"name":"Alongamento de peito","duration":"30s","instructions":"Estique os braços para trás"}},{{"name":"Alongamento de tríceps","duration":"30s","instructions":"Puxe o cotovelo atrás da cabeça"}}]}},{{"day_name":"Dia 2","muscle_groups":["pernas","glúteos"],"exercises":[...],"warm_up":[...],"cool_down":[...]}}]}}

REGRAS ESPECÍFICAS:
1. SEGURANÇA PRIMEIRO: Adapte exercícios para limitações de saúde
2. PROGRESSÃO: Adeque intensidade ao nível {fitness_level}
3. VARIEDADE: Inclua diferentes tipos de exercícios
4. PRATICIDADE: {'Exercícios que podem ser feitos em casa' if workout_type == 'casa' else 'Use equipamentos da academia de forma eficiente'}
5. DIAS: Crie plano para exatamente {days_per_week} dias diferentes
6. GRUPOS MUSCULARES: Distribua de forma equilibrada
7. MODIFICAÇÕES: Sempre inclua adaptações para iniciantes/limitações

IMPORTANTE: 
- Se há problemas cardíacos/respiratórios: intensidade baixa, pausas frequentes
- Se há problemas articulares: evitar impacto, foco em mobilidade
- Se há lesões: exercícios alternativos seguros
- Nível {fitness_level}: ajuste séries, repetições e dificuldade adequadamente

Retorne APENAS o JSON do plano completo, sem explicações."""

    print(f"[DEBUG] Chamando OpenAI para treino com prompt de {len(prompt)} chars")
    
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=4000
        )
        
        print(f"[DEBUG] OpenAI respondeu com sucesso para treino")
        
        import json
        import re
        
        # Pega a resposta
        content = response.choices[0].message.content
        print(f"[DEBUG] Workout content length: {len(content)}")
        
        # Remove possíveis markdown ou texto extra
        content = re.sub(r'^```json\s*', '', content)
        content = re.sub(r'\s*```$', '', content)
        content = content.strip()
        
        # Tenta fazer parse
        try:
            result = json.loads(content)
            print(f"[DEBUG] Workout JSON parseado com sucesso. Keys: {list(result.keys()) if isinstance(result, dict) else 'Not dict'}")
            return result
        except json.JSONDecodeError as e:
            print(f"[DEBUG] Erro ao parsear workout JSON: {e}")
            # Se falhar, salva para debug
            with open('error_workout_response.txt', 'w', encoding='utf-8') as f:
                f.write(f"ERRO: {e}\n\n")
                f.write(f"POSIÇÃO: linha {e.lineno}, coluna {e.colno}, char {e.pos}\n\n")
                f.write("RESPOSTA:\n")
                f.write(content)
            raise Exception(f"Erro ao parsear JSON do treino da OpenAI. Detalhes salvos em error_workout_response.txt: {e}")
            
    except Exception as e:
        print(f"[DEBUG] Erro geral na chamada OpenAI para treino: {e}")
        raise

def generate_workout_plan(user_profile, questionnaire_data):
    """
    Gera um plano de treino personalizado baseado no perfil do usuário e questionário
    """
    try:
        print(f"[AI_SERVICE] Gerando plano de treino para usuário...")
        
        # Construir o prompt personalizado para treino
        workout_prompt = f"""
        Você é um personal trainer especializado. Crie um plano de treino COMPLETO e DETALHADO baseado nas seguintes informações:
        
        PERFIL DO USUÁRIO:
        - Nome: {user_profile.get('name', 'Não informado')}
        - Idade: {user_profile.get('age', 'Não informado')} anos
        - Peso: {user_profile.get('weight', 'Não informado')} kg
        - Altura: {user_profile.get('height', 'Não informado')} cm
        - Sexo: {user_profile.get('gender', 'Não informado')}
        - Objetivo: {user_profile.get('goal', 'Não informado')}
        
        QUESTIONÁRIO DE TREINO:
        - Problemas de saúde: {questionnaire_data.get('healthProblems', [])}
        - Lesões anteriores: {questionnaire_data.get('previousInjuries', [])}
        - Nível de condicionamento: {questionnaire_data.get('fitnessLevel', 'Não informado')}
        - Preferências de exercício: {questionnaire_data.get('exercisePreferences', [])}
        - Tipo de treino: {questionnaire_data.get('workoutType', 'Não informado')}
        - Dias por semana: {questionnaire_data.get('daysPerWeek', 'Não informado')}
        - Horários disponíveis: {questionnaire_data.get('availableTimes', [])}
        
        INSTRUÇÕES ESPECÍFICAS:
        1. Crie um plano de {questionnaire_data.get('daysPerWeek', 3)} dias por semana
        2. Considere o tipo: {questionnaire_data.get('workoutType', 'casa')}
        3. Respeite limitações de saúde e lesões anteriores
        4. Inclua aquecimento e alongamento
        5. Forneça alternativas para exercícios quando necessário
        
        FORMATO DE RESPOSTA:
        Retorne um JSON com a seguinte estrutura:
        {{
            "plan_name": "Nome do Plano",
            "plan_summary": "Resumo do plano em 2-3 linhas",
            "workout_schedule": [
                {{
                    "day": "Segunda-feira",
                    "focus": "Foco do treino (ex: Peito e Tríceps)",
                    "exercises": [
                        {{
                            "name": "Nome do exercício",
                            "sets": "3",
                            "reps": "12-15",
                            "rest": "60 segundos",
                            "instructions": "Instruções detalhadas",
                            "equipment": "Equipamento necessário"
                        }}
                    ]
                }}
            ],
            "important_notes": [
                "Nota importante 1",
                "Nota importante 2"
            ],
            "progression_tips": "Como progredir no treino"
        }}
        
        IMPORTANTE: 
        1. Retorne APENAS o JSON válido, sem texto adicional antes ou depois
        2. Certifique-se de que todas as strings estão entre aspas duplas
        3. Escape caracteres especiais (aspas, quebras de linha) nas strings
        4. Não inclua comentários ou explicações no JSON
        5. Termine todas as strings e feche todas as chaves corretamente
        """
        
        try:
            # Gerar resposta usando o serviço de IA
            messages = [{"role": "user", "content": workout_prompt}]
            ai_response = get_ai_response(messages, user_profile)
            
            print(f"[AI_SERVICE] Resposta da IA recebida: {ai_response[:200]}...")
            
            return ai_response
            
        except Exception as e:
            print(f"Erro ao gerar plano de treino: {str(e)}")
            raise Exception(f"Erro na geração do treino: {str(e)}")

    except Exception as e:
        print(f"Erro geral no serviço de treino: {str(e)}")
        raise Exception(f"Erro no serviço de treino: {str(e)}")
