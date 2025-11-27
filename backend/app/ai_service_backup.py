from openai import OpenAI
from app.config import settings
import json
import re

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

    # Detectar se é uma requisição de workout baseada no conteúdo
    is_workout_request = any('workout' in msg.get('content', '').lower() or 'treino' in msg.get('content', '').lower() for msg in messages)
    
    if is_workout_request:
        # Para workout, usar mais tokens e formato JSON
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=all_messages,
            temperature=0.7,
            max_tokens=4096,  # Mais tokens para workouts complexos
            response_format={"type": "json_object"}  # Forçar JSON válido
        )
    else:
        # Para chat normal
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=all_messages,
            temperature=0.7,
            max_tokens=2000
        )

    content = response.choices[0].message.content
    
    # Se for workout, validar e limpar JSON
    if is_workout_request:
        try:
            # Tentar validar o JSON
            json.loads(content)
            return content
        except json.JSONDecodeError as e:
            print(f"[AI_SERVICE] ⚠️ JSON inválido da IA: {e}")
            # Tentar extrair JSON válido
            content = re.sub(r'^```json\s*', '', content)
            content = re.sub(r'\s*```$', '', content)
            content = content.strip()
            
            # Tentar encontrar início e fim do JSON
            start_brace = content.find('{')
            last_brace = content.rfind('}')
            
            if start_brace != -1 and last_brace > start_brace:
                clean_json = content[start_brace:last_brace + 1]
                try:
                    json.loads(clean_json)
                    print(f"[AI_SERVICE] ✅ JSON corrigido com sucesso")
                    return clean_json
                except json.JSONDecodeError:
                    print(f"[AI_SERVICE] ❌ Não foi possível corrigir o JSON")
            
            raise Exception(f"Resposta da IA não é JSON válido: {e}")
    
    return content


def generate_meal_plan(user_profile: dict, previous_plans: list = None) -> dict:
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

    # Verificar se há planos anteriores (simulação - em implementação real, buscar do banco)
    previous_plans = []  # TODO: Buscar planos anteriores do usuário
    
    previous_plan_context = ""
    if previous_plans:
        previous_plan_context = f"""
📋 PLANO ANTERIOR ANALISADO:
{previous_plans[-1] if previous_plans else 'Nenhum plano anterior'}

🔄 INSTRUÇÕES DE VARIAÇÃO:
- SUBSTITUA alimentos incomuns ou caros por opções básicas brasileiras
- MANTENHA sempre: arroz, feijão, frango, ovo, carne bovina, batata, banana
- VARIE apenas temperos, formas de preparo e acompanhamentos
- EVITE repetir pratos idênticos do plano anterior
"""
    
    prompt = f"""🍎 Dr. Nutri - Nutricionista Especialista em Composição Corporal 🇧🇷

{previous_plan_context}

🎯 NOVA MISSÃO: Criar PLANO ALIMENTAR com MEDIDAS PRECISAS e alimentos BÁSICOS brasileiros acessíveis.

📊 PERFIL COMPLETO DO CLIENTE:
- Peso atual: {weight}kg
- Altura: {height}cm  
- Idade: {age} anos
- Peso alvo: {target_weight}kg
- 🎯 OBJETIVO PRINCIPAL: {objetivo} ({objetivo_text})
- 💪 Nível de atividade: {activity_level}
- 🔥 Calorias diárias: {calories} kcal
- 🚫 Restrições: {restriction_text if restriction_text else "Nenhuma"}
- ❤️ Preferências: {preference_text if preference_text else "Nenhuma"}

🎯 ESTRATÉGIA NUTRICIONAL ESPECÍFICA PARA {objetivo}:

{"🔥 FOCO EMAGRECIMENTO (Deficit Calórico Inteligente):" if objetivo == "EMAGRECER" else ""}
{"- Proteína ALTA: 1.6-2.2g por kg de peso corporal para preservar massa muscular" if objetivo == "EMAGRECER" else ""}
{"- Carboidratos MODERADOS: Preferencialmente nos períodos pré/pós treino" if objetivo == "EMAGRECER" else ""}
{"- Gorduras CONTROLADAS: 20-25% das calorias, priorizando ômegas e MCT" if objetivo == "EMAGRECER" else ""}
{"- Fibras ALTAS: Verduras à vontade para saciedade e metabolismo" if objetivo == "EMAGRECER" else ""}
{"- Hidratação EXTRA: Acelera metabolismo e reduz fome falsa" if objetivo == "EMAGRECER" else ""}

{"💪 FOCO GANHO DE MASSA (Superavit Calórico Limpo):" if objetivo == "GANHAR PESO" else ""}
{"- Proteína OTIMIZADA: 2.0-2.5g por kg de peso para síntese proteica máxima" if objetivo == "GANHAR PESO" else ""}
{"- Carboidratos ESTRATÉGICOS: Maior quantidade pré/pós treino para performance" if objetivo == "GANHAR PESO" else ""}
{"- Gorduras SAUDÁVEIS: 25-30% das calorias para produção hormonal" if objetivo == "GANHAR PESO" else ""}
{"- Timing NUTRICIONAL: Refeições frequentes para anabolismo constante" if objetivo == "GANHAR PESO" else ""}
{"- Micronutrientes: Foco em magnésio, zinco, vitamina D para crescimento" if objetivo == "GANHAR PESO" else ""}

{"⚖️ FOCO MANUTENÇÃO (Equilíbrio Metabólico):" if objetivo == "MANTER PESO" else ""}
{"- Proteína BALANCEADA: 1.4-1.8g por kg para manutenção muscular" if objetivo == "MANTER PESO" else ""}
{"- Macros EQUILIBRADOS: 45% carbo, 30% proteína, 25% gordura" if objetivo == "MANTER PESO" else ""}
{"- Flexibilidade SOCIAL: 80/20 - disciplina com margem para vida social" if objetivo == "MANTER PESO" else ""}

🍽️ PLANO ALIMENTAR ESTRATÉGICO POR REFEIÇÃO:

☀️ CAFÉ DA MANHÃ - ENERGIA E ATIVAÇÃO METABÓLICA ({int(calories * 0.2)}-{int(calories * 0.25)} kcal):
🥖 Carboidratos ({objetivo}) - MEDIDAS EXATAS: {"REDUZIDOS - 50g pão francês OU 30g aveia" if objetivo == "EMAGRECER" else "MODERADOS - 75g pão OU 45g aveia" if objetivo == "MANTER PESO" else "GENEROSOS - 100g pão OU 60g aveia + 100g banana"}: 
    • Opções BÁSICAS: 50-100g pão francês, 30-60g aveia em flocos, 80g tapioca, 150g batata doce cozida, 100-150g banana
🥚 Proteínas (ESSENCIAL - {objetivo}) - MEDIDAS EXATAS: {"ALTA - 120g ovos (2 unidades) + 200ml leite + 30g queijo minas" if objetivo == "EMAGRECER" else "MODERADA - 60g ovos (1 unidade) + 200ml leite" if objetivo == "MANTER PESO" else "REFORÇADA - 180g ovos (3 unidades) OU 300ml leite + 40g queijo"}: 
    • Opções BÁSICAS: 60-180g ovos mexidos, 200-300ml leite integral, 150g iogurte natural, 30-50g queijo minas, 20g requeijão
🥑 Gorduras Saudáveis - MEDIDAS EXATAS: {"MÍNIMO - 5ml azeite (1 col chá)" if objetivo == "EMAGRECER" else "EQUILIBRADO - 10ml azeite (1 col sobremesa)" if objetivo == "MANTER PESO" else "LIBERAL - 15ml azeite OU 20g castanhas"}: 
    • Opções BÁSICAS: 5-15ml azeite extra virgem, 15-30g castanhas do pará, 20g amendoim torrado, 50g abacate
🍎 Frutas e Fibras: {"LIBERADO - frutas com fibras" if objetivo == "EMAGRECER" else "1-2 porções frutas" if objetivo == "MANTER PESO" else "2-3 frutas + vitamina"}: 
    • Opções: maçã, mamão, laranja, melancia, morango

🍛 ALMOÇO - REFEIÇÃO PRINCIPAL ANABÓLICA ({int(calories * 0.35)}-{int(calories * 0.4)} kcal):
🍚 Carboidratos Energéticos ({objetivo}) - MEDIDAS EXATAS: {"CONTROLADO - 120g arroz cozido + 80g feijão" if objetivo == "EMAGRECER" else "BALANCEADO - 150g arroz + 100g feijão" if objetivo == "MANTER PESO" else "POTENTE - 200g arroz + 120g feijão + 150g batata"}: 
    • Opções BÁSICAS: 120-200g arroz branco cozido, 80-120g feijão carioca, 150-200g batata cozida, 100g macarrão cozido
🥩 Proteínas Musculares (PRIORIDADE {objetivo}) - MEDIDAS EXATAS: {"ALTA - 150g frango OU 120g carne bovina" if objetivo == "EMAGRECER" else "SÓLIDA - 120g frango OU 100g carne" if objetivo == "MANTER PESO" else "MÁXIMA - 180g frango OU 150g carne + 60g ovo"}: 
    • Opções BÁSICAS: 100-180g peito de frango grelhado, 80-150g carne bovina magra, 120g peixe (tilápia/sardinha), 60-120g ovos cozidos
🛢️ Gorduras Funcionais: {"MÍNIMO - só tempero" if objetivo == "EMAGRECER" else "MODERADO - 1 col óleo" if objetivo == "MANTER PESO" else "GENEROSO - 2 col azeite no preparo"}: 
    • Opções: azeite extra virgem, óleo de coco, óleo de canola
🥗 Verduras e Legumes (METABOLISMO) - MEDIDAS EXATAS: {"MÁXIMO - 200g salada mista + 150g legumes refogados" if objetivo == "EMAGRECER" else "BOM PRATO - 150g salada + 100g refogado" if objetivo == "MANTER PESO" else "COLORIDO - 100g salada + 200g legumes variados"}: 
    • Opções BÁSICAS: 100-200g alface, 100g tomate, 80g cenoura cozida, 100g abobrinha refogada, 80g chuchu, 100g brócolis

🥙 LANCHE DA TARDE - SUSTENTAÇÃO ENERGÉTICA ({int(calories * 0.1)}-{int(calories * 0.15)} kcal):
🍪 Carboidratos Táticos ({objetivo}): {"EVITAR ou só fruta" if objetivo == "EMAGRECER" else "LEVE - 2-3 biscoitos" if objetivo == "MANTER PESO" else "SUBSTANCIAL - sanduíche ou vitamina"}: 
    • Opções: {"frutas com fibras, biscoito integral (só 1-2)" if objetivo == "EMAGRECER" else "biscoito água/sal, pão forma, fruta" if objetivo == "MANTER PESO" else "pão francês, biscoito recheado, vitamina com banana"}
🧀 Proteínas de Manutenção (CRUCIAL): {"REFORÇADA - iogurte + queijo" if objetivo == "EMAGRECER" else "SÓLIDA - queijo ou iogurte" if objetivo == "MANTER PESO" else "COMPLETA - vitamina proteica ou sanduíche com queijo"}: 
    • Opções: queijo minas, iogurte natural, leite, requeijão light
🥜 Gorduras Seletivas: {"SÓ NO PREPARO - mínimo" if objetivo == "EMAGRECER" else "CONTROLADO - algumas castanhas" if objetivo == "MANTER PESO" else "NUTRITIVO - mix de castanhas ou pasta amendoim"}: 
    • Opções: {"azeite mínimo tempero" if objetivo == "EMAGRECER" else "castanhas, amendoim torrado" if objetivo == "MANTER PESO" else "castanhas variadas, pasta amendoim, coco ralado"}

🌙 JANTAR - RECUPERAÇÃO E REGENERAÇÃO NOTURNA ({int(calories * 0.25)}-{int(calories * 0.3)} kcal):
🍝 Carboidratos Noturnos ({objetivo}): {"MÍNIMO - só legumes OU 2-3 col arroz" if objetivo == "EMAGRECER" else "MODERADO - 4-5 col arroz ou batata" if objetivo == "MANTER PESO" else "COMPLETO - arroz + batata ou macarrão"}: 
    • Opções: {"batata doce pequena, arroz integral (pouco)" if objetivo == "EMAGRECER" else "arroz branco, batata cozida, macarrão" if objetivo == "MANTER PESO" else "arroz, macarrão, batata, mandioca"}
🍗 Proteínas Reparadoras (MÁXIMA PRIORIDADE): {"ALTA - 120-150g proteína magra" if objetivo == "EMAGRECER" else "SÓLIDA - 100-120g" if objetivo == "MANTER PESO" else "ROBUSTA - 150-200g + ovo adicional"}: 
    • Opções: frango desfiado, peixe grelhado, ovo mexido, queijo cottage, sardinha, atum
🫒 Gorduras Digestivas: {"SÓ TEMPERO - azeite mínimo" if objetivo == "EMAGRECER" else "FUNCIONAL - 1 col azeite" if objetivo == "MANTER PESO" else "NUTRITIVO - 2 col azeite + oleaginosas"}: 
    • Opções: azeite extra virgem, óleo de coco, castanhas (pouquíssimas se emagrecimento)
🥬 Verduras e Fibras (DETOX NOTURNO): {"MÁXIMO - salada gigante + sopa" if objetivo == "EMAGRECER" else "ABUNDANTE - salada + refogado" if objetivo == "MANTER PESO" else "VARIADO - salada colorida + legumes"}: 
    • Opções: alface, rúcula, tomate, pepino, sopa de legumes, abobrinha, chuchu refogado

📋 ESTRUTURA JSON OBRIGATÓRIA COM MEDIDAS PRECISAS:
{{"day":1,"meals":[{{"type":"breakfast","carbs_foods":["60g pão francês","45g aveia em flocos","100g banana","80g tapioca"],"protein_foods":["120g ovos mexidos (2 unidades)","200ml leite integral","150g iogurte natural","30g queijo minas"],"fat_foods":["10ml azeite extra virgem","20g castanhas do pará","15g amendoim torrado"],"vegetables":["100g banana","150g maçã","120g mamão","200g laranja"]}},{{"type":"lunch","carbs_foods":["150g arroz branco cozido","100g feijão carioca","150g batata cozida","100g macarrão"],"protein_foods":["120g frango grelhado","100g carne bovina magra","120g peixe tilápia","60g ovo cozido"],"fat_foods":["10ml óleo de soja","15ml azeite extra virgem"],"vegetables":["150g alface","100g tomate","80g cenoura cozida","100g abobrinha refogada","80g chuchu"]}},{{"type":"afternoon_snack","carbs_foods":["30g biscoito água e sal","50g pão de forma","100g fruta da época"],"protein_foods":["30g queijo minas","150g iogurte natural","200ml leite"],"fat_foods":["15g castanhas","20g amendoim torrado"],"vegetables":[]}},{{"type":"dinner","carbs_foods":["120g arroz branco","150g batata cozida","80g macarrão"],"protein_foods":["120g frango desfiado","60g ovo mexido","30g queijo branco","100g sardinha"],"fat_foods":["10ml azeite","5ml óleo de soja"],"vegetables":["200g salada verde mista","150ml sopa de legumes","100g abobrinha refogada"]}}]}}

🎯 REGRAS ESTRATÉGICAS Dr. Nutri - PERSONALIZAÇÃO TOTAL:

🇧🇷 BASE ALIMENTAR OBRIGATÓRIA - ALIMENTOS BÁSICOS BRASILEIROS:
   ✅ SEMPRE INCLUIR: arroz branco, feijão carioca, frango, ovos, carne bovina, batata, banana, pão francês
   ✅ TEMPEROS BÁSICOS: alho, cebola, sal, óleo de soja, azeite
   🚫 EVITAR: quinoa, chia, açaí, salmão, queijos importados, alimentos caros/exóticos
   📏 TODAS AS QUANTIDADES: Sempre em gramas (g) para sólidos, mililitros (ml) para líquidos

🚫 RESTRIÇÕES RESPEITADAS: {restriction_text}
❤️ PREFERÊNCIAS INCLUÍDAS: {preference_text}

🔥 ESTRATÉGIA {objetivo} ESPECÍFICA:
{"• PROTEÍNA: 1.6-2.2g/kg peso = " + str(int(weight * 1.8)) + "g/dia (ESSENCIAL para preservar músculo)" if objetivo == "EMAGRECER" else ""}
{"• CARBOIDRATO: Reduzido, foco pré/pós treino e manhã" if objetivo == "EMAGRECER" else ""}  
{"• GORDURA: 20-25% calorias = " + str(int(calories * 0.23 / 9)) + "g/dia máximo" if objetivo == "EMAGRECER" else ""}
{"• FIBRAS: Máximo possível (verduras à vontade) para saciedade" if objetivo == "EMAGRECER" else ""}
{"• TIMING: Jantar com pouco carbo, mais proteína" if objetivo == "EMAGRECER" else ""}

{"• PROTEÍNA: 2.0-2.5g/kg peso = " + str(int(weight * 2.2)) + "g/dia (ANABOLISMO máximo)" if objetivo == "GANHAR PESO" else ""}
{"• CARBOIDRATO: Liberal, especialmente pré/pós treino" if objetivo == "GANHAR PESO" else ""}
{"• GORDURA: 25-30% calorias = " + str(int(calories * 0.28 / 9)) + "g/dia" if objetivo == "GANHAR PESO" else ""}
{"• FREQUÊNCIA: 4-5 refeições para manter anabolismo" if objetivo == "GANHAR PESO" else ""}
{"• TIMING: Carboidrato em todas as refeições" if objetivo == "GANHAR PESO" else ""}

{"• PROTEÍNA: 1.4-1.8g/kg peso = " + str(int(weight * 1.6)) + "g/dia (MANUTENÇÃO)" if objetivo == "MANTER PESO" else ""}
{"• EQUILÍBRIO: 45% carbo, 30% proteína, 25% gordura" if objetivo == "MANTER PESO" else ""}
{"• FLEXIBILIDADE: 80/20 - disciplina com margem social" if objetivo == "MANTER PESO" else ""}

🏃 ATIVIDADE {activity_level.upper()}: {"Carboidratos PRÉ treino (banana, pão) e PÓS treino (arroz, batata)" if activity_level in ["alto", "muito alto"] else "Carboidratos moderados, foco em manhã e almoço"}

⏰ FATOR IDADE ({age} anos): {"Metabolismo 15-20% mais lento - reduza porções gerais em 10-15%" if age > 50 else "Metabolismo ativo - porções normais" if age >= 30 else "Metabolismo acelerado - pode aumentar porções 10%"}

📊 ESTRUTURA TÉCNICA OBRIGATÓRIA:
• Separe por grupos: carbs_foods, protein_foods, fat_foods, vegetables  
• Liste alimentos ESPECÍFICOS, não receitas completas
• Dê VARIEDADE em cada grupo (mínimo 4 opções por grupo)
• QUANTIDADES orientativas baseadas no objetivo {objetivo}
• Progressão nutricional: {weight}kg → {target_weight}kg

🔄 REGRAS DE VARIAÇÃO INTELIGENTE - OBRIGATÓRIAS:
1. 🚫 PROIBIDO repetir mais de 40% dos alimentos dos últimos planos!
2. 🔄 Para CARBOIDRATOS: Se plano anterior teve arroz doce + pão francês + tapioca, use arroz branco + macarrão + batata doce
3. 🔄 Para PROTEÍNAS: Se plano anterior teve 4 ovos + leite + iogurte, use frango + carne moída + queijo cottage
4. 🇧🇷 ALIMENTOS BÁSICOS PERMITIDOS (pode repetir): arroz branco, feijão carioca, frango, ovos, carne bovina
5. 🚫 EVITE REPETIR: alimentos específicos como "arroz doce", "biscoito integral", "iogurte natural", "queijo minas"
6. ✅ SUBSTITUA POR: pão integral, macarrão, batata, mandioca, aveia em flocos, leite desnatado, ricota, queijo branco
7. 📏 TODAS as quantidades DEVEM estar em gramas (g) ou mililitros (ml)
8. 🔀 VARIE formas de preparo: arroz branco vs arroz integral vs macarrão vs batata

💡 DICAS BONUS PARA {objetivo}:
{"• Beba 2-3L água/dia • Masque devagar • Verduras à vontade • Evite líquidos durante refeições" if objetivo == "EMAGRECER" else ""}
{"• Smoothies calóricos • Oleaginosas entre refeições • Não pule refeições • Leite integral" if objetivo == "GANHAR PESO" else ""}
{"• Flexibilidade 80/20 • Escute o corpo • Varie preparos • Mantenha prazer na comida" if objetivo == "MANTER PESO" else ""}

🎯 VERIFICAÇÃO FINAL OBRIGATÓRIA:
✅ Todas as quantidades estão em gramas (g) ou mililitros (ml)?
✅ Todos os alimentos são básicos e acessíveis no Brasil?
✅ Evitei alimentos caros como quinoa, chia, salmão, açaí?
✅ Incluí arroz, feijão, frango, ovos como base?
✅ As porções estão adequadas para o objetivo {objetivo}?

Retorne APENAS o JSON de 1 dia modelo personalizado com medidas EXATAS em gramas/ml, sem explicações."""

    # Adicionar informações de planos anteriores se disponíveis
    previous_foods_info = ""
    if previous_plans and len(previous_plans) > 0:
        previous_foods_info = "\n\n🔄 PLANOS ANTERIORES PARA EVITAR REPETIÇÕES:\n"
        
        for i, prev_plan in enumerate(previous_plans[:2], 1):  # Máximo 2 planos anteriores
            previous_foods_info += f"\n📋 {prev_plan['plan_name']} (criado em {prev_plan['created_at'][:10]}):"
            
            try:
                if isinstance(prev_plan['plan_data'], dict):
                    plan_data = prev_plan['plan_data']
                else:
                    plan_data = json.loads(prev_plan['plan_data'])
                
                # Extrair alimentos dos dias anteriores
                used_foods = set()
                print(f"[DEBUG] Processando plano: {prev_plan['plan_name']}")
                print(f"[DEBUG] Estrutura do plan_data: {list(plan_data.keys()) if isinstance(plan_data, dict) else 'Não é dict'}")
                
                if 'days' in plan_data:
                    print(f"[DEBUG] Encontrados {len(plan_data['days'])} dias no plano")
                    for day_idx, day in enumerate(plan_data['days']):
                        print(f"[DEBUG] Dia {day_idx}: {list(day.keys()) if isinstance(day, dict) else 'Não é dict'}")
                        if 'meals' in day:
                            print(f"[DEBUG] Refeições encontradas: {list(day['meals'].keys())}")
                            for meal_key, meal_data in day['meals'].items():
                                if isinstance(meal_data, dict) and 'foods' in meal_data:
                                    print(f"[DEBUG] {meal_key}: {len(meal_data['foods'])} alimentos")
                                    for food in meal_data['foods']:
                                        if isinstance(food, dict) and 'name' in food:
                                            used_foods.add(food['name'].lower())
                                            print(f"[DEBUG] Alimento extraído: {food['name']}")
                                        elif isinstance(food, str):
                                            used_foods.add(food.lower())
                                            print(f"[DEBUG] Alimento string extraído: {food}")
                else:
                    print(f"[DEBUG] Chave 'days' não encontrada no plano. Chaves disponíveis: {list(plan_data.keys())}")
                
                if used_foods:
                    foods_list = list(used_foods)[:12]  # Máximo 12 alimentos principais
                    previous_foods_info += f"\n   🚫 NÃO USE NOVAMENTE: {', '.join(foods_list)}"
                    previous_foods_info += f"\n   ✅ SUBSTITUA POR EQUIVALENTES DIFERENTES!"
                else:
                    previous_foods_info += " Nenhum alimento específico detectado"
                    
            except Exception as e:
                print(f"[DEBUG] Erro ao processar plano anterior: {e}")
                previous_foods_info += " (erro ao processar dados)"
        
        previous_foods_info += "\n\n🚨 ATENÇÃO CRÍTICA - VARIAÇÃO OBRIGATÓRIA:"
        previous_foods_info += "\n🚫 MÁXIMO 30% dos alimentos podem repetir dos planos acima!"
        previous_foods_info += "\n✅ 70% DEVEM ser alimentos DIFERENTES para garantir variedade!"
        previous_foods_info += "\n🔄 EXEMPLOS DE SUBSTITUIÇÃO:"
        previous_foods_info += "\n   • Arroz doce → Arroz branco/integral/macarrão/batata doce"
        previous_foods_info += "\n   • Pão francês → Pão integral/tapioca/biscoito/torrada"
        previous_foods_info += "\n   • Iogurte natural → Leite/queijo cottage/ricota/vitamina"
        previous_foods_info += "\n   • Queijo minas → Queijo branco/requeijão/cream cheese"
        previous_foods_info += "\n✅ MANTENHA apenas: arroz, feijão, frango, ovos (base da dieta brasileira)"
        previous_foods_info += "\n🎯 OBJETIVO: Cada plano deve parecer DIFERENTE do anterior!"
    else:
        previous_foods_info = "\n\n📝 PRIMEIRO PLANO: Foque em alimentos brasileiros básicos e nutritivos."
    
    # Adicionar informações ao prompt final
    prompt += previous_foods_info

    print(f"[DEBUG] ===== PROMPT FINAL PARA OPENAI =====")
    print(f"[DEBUG] Tamanho do prompt: {len(prompt)} chars")
    print(f"[DEBUG] Informações de planos anteriores incluídas:")
    print(f"[DEBUG] {previous_foods_info[:500]}...") # Primeiros 500 chars
    if previous_plans:
        print(f"[DEBUG] Incluindo {len(previous_plans)} planos anteriores para evitar repetições")
    print(f"[DEBUG] ===== FIM DO DEBUG DO PROMPT =====")
    
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

FORMATO JSON OBRIGATÓRIO (INCLUA 5-6 EXERCÍCIOS POR DIA):
{{"workout_type":"{workout_type}","days_per_week":{days_per_week},"fitness_level":"{fitness_level}","health_considerations":"{health_text}","workout_days":[{{"day_name":"Dia 1","muscle_groups":["peitoral","tríceps"],"exercises":[{{"name":"Flexão de braço","sets":3,"reps":"8-12","rest":"60s","instructions":"Mantenha o corpo reto, desça até quase tocar o peito no chão","modifications":"Se necessário, apoie os joelhos"}},{{"name":"Flexão diamante","sets":2,"reps":"5-8","rest":"60s","instructions":"Forme um diamante com as mãos, foque no tríceps","modifications":"Versão mais fácil: flexão normal"}},{{"name":"Flexão inclinada","sets":3,"reps":"10-15","rest":"60s","instructions":"Pés elevados em superfície","modifications":"Use banco ou sofá"}},{{"name":"Mergulho em cadeira","sets":3,"reps":"8-12","rest":"60s","instructions":"Use duas cadeiras estáveis","modifications":"Apoie os pés no chão"}},{{"name":"Prancha com toque no ombro","sets":2,"reps":"10 cada lado","rest":"45s","instructions":"Mantenha o corpo estável","modifications":"Apoie os joelhos"}},{{"name":"Burpee modificado","sets":2,"reps":"5-8","rest":"90s","instructions":"Movimento completo controlado","modifications":"Sem pulo final"}}],"warm_up":[{{"name":"Rotação de braços","duration":"30s","instructions":"Movimentos circulares com os braços"}},{{"name":"Alongamento dinâmico","duration":"1min","instructions":"Movimentos suaves para aquecer"}}],"cool_down":[{{"name":"Alongamento de peito","duration":"30s","instructions":"Estique os braços para trás"}},{{"name":"Alongamento de tríceps","duration":"30s","instructions":"Puxe o cotovelo atrás da cabeça"}}]}},{{"day_name":"Dia 2","muscle_groups":["pernas","glúteos"],"exercises":[...],"warm_up":[...],"cool_down":[...]}}]}}

REGRAS ESPECÍFICAS:
1. SEGURANÇA PRIMEIRO: Adapte exercícios para limitações de saúde
2. PROGRESSÃO: Adeque intensidade ao nível {fitness_level}
3. VARIEDADE: Inclua diferentes tipos de exercícios
4. QUANTIDADE DE EXERCÍCIOS: SEMPRE inclua 5-6 exercícios por dia de treino (mínimo 5, máximo 6)
4.1. CARDIO OBRIGATÓRIO: Se 'cardio' estiver nas preferências, inclua pelo menos 1-2 exercícios cardiovasculares por sessão
5. PRATICIDADE: {'Exercícios que podem ser feitos em casa' if workout_type == 'casa' else 'Use equipamentos da academia de forma eficiente'}
6. DIAS: Crie plano para exatamente {days_per_week} dias diferentes
7. GRUPOS MUSCULARES: Distribua de forma equilibrada
8. MODIFICAÇÕES: Sempre inclua adaptações para iniciantes/limitações

IMPORTANTE: 
- Se há problemas cardíacos/respiratórios: intensidade baixa, pausas frequentes
- Se há problemas articulares: evitar impacto, foco em mobilidade
- Se há lesões: exercícios alternativos seguros
- Nível {fitness_level}: ajuste séries, repetições e dificuldade adequadamente
- PREFERÊNCIAS: {', '.join(exercise_preferences) if exercise_preferences else 'Nenhuma'} - INCLUA estes exercícios obrigatoriamente
- Se CARDIO está nas preferências: inclua corrida no lugar, jumping jacks, burpees, mountain climbers, high knees

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
        print(f"[AI_SERVICE] ===== INÍCIO DEBUG TREINO =====")
        print(f"[AI_SERVICE] Gerando plano de treino para usuário...")
        print(f"[AI_SERVICE] 📊 Dados do questionário COMPLETO: {questionnaire_data}")
        print(f"[AI_SERVICE] 👤 Perfil do usuário COMPLETO: {user_profile}")
        
        # Extrair dados específicos para validação
        days_per_week = questionnaire_data.get('days_per_week', 3)
        available_days = questionnaire_data.get('available_days', [])
        workout_type = questionnaire_data.get('workout_type', 'casa')
        session_duration = questionnaire_data.get('session_duration', 60)
        
        print(f"[AI_SERVICE] 🔍 DADOS EXTRAÍDOS:")
        print(f"[AI_SERVICE] - days_per_week: {days_per_week} (tipo: {type(days_per_week)})")
        print(f"[AI_SERVICE] - available_days: {available_days}")
        print(f"[AI_SERVICE] - workout_type: {workout_type}")
        print(f"[AI_SERVICE] - session_duration: {session_duration}")
        
        if days_per_week != 4:
            print(f"[AI_SERVICE] ⚠️ PROBLEMA: days_per_week deveria ser 4 mas é {days_per_week}")
        
        # Verificar esportes específicos nas preferências
        preferred_exercises = questionnaire_data.get('preferred_exercises', [])
        has_cardio = any(exercise.lower() in ['cardio', 'aeróbico', 'cardio/aeróbico'] 
                        for exercise in preferred_exercises)
        has_running = any('corrida' in exercise.lower() for exercise in preferred_exercises)
        has_swimming = any('natação' in exercise.lower() for exercise in preferred_exercises)
        has_sports = any(sport in exercise.lower() for exercise in preferred_exercises 
                        for sport in ['futebol', 'basquete', 'vôlei', 'tênis', 'ciclismo'])
        
        # Ajustar prompt baseado nos esportes
        sports_instruction = ""
        if has_running:
            sports_instruction += "\\n⚠️ CORRIDA detectada: Substitua 1 dia por 'Dia de Corrida - 30-45min de corrida + alongamento'"
        if has_swimming:
            sports_instruction += "\\n⚠️ NATAÇÃO detectada: Substitua 1 dia por 'Dia de Natação - 45-60min de natação + exercícios aquáticos'"
        if has_sports:
            sports_instruction += "\\n⚠️ ESPORTE detectado: Inclua 1 dia específico para o esporte mencionado"
        
        print(f"[AI_SERVICE] 🏃 Esportes detectados - Corrida: {has_running}, Natação: {has_swimming}, Outros: {has_sports}")
        
        # Construir o prompt personalizado para treino
        workout_prompt = f"""
        Opa! Aqui é o Coach Atlas 💪 - Seu Personal Trainer Virtual brasileiro!
        
        🎯 MINHA MISSÃO: Criar treinos personalizados usando apenas halteres e máquinas encontradas nas academias brasileiras.
        🗣️ MEU ESTILO: Direto, motivador, simples e acolhedor - sem enrolação!
        🇧🇷 LINGUAGEM: Brasileiro raiz, informal moderado, sem termos técnicos complicados. 
        
        🔥 ATENÇÃO PARCEIRO: Vamos montar um treino de {days_per_week} DIAS POR SEMANA!
        Não vou criar menos dias - você pediu {days_per_week}, vai ser {days_per_week} mesmo!
        
        🚫 ATENÇÃO EXERCÍCIOS: CADA DIA DEVE TER 5-6 EXERCÍCIOS! NÃO 3!
        ⚠️ SE CRIAR SÓ 3 EXERCÍCIOS POR DIA, ESTARÁ ERRADO!
        
        📋 DADOS DO MEU ALUNO:
        - Nome: Parceiro(a) 🤝
        - Idade: {user_profile.get('age', 'Não informado')} anos
        - Peso atual: {user_profile.get('weight', 'Não informado')} kg
        - Altura: {user_profile.get('height', 'Não informado')} cm
        - Sexo: {user_profile.get('gender', 'Não informado')}
        - Meta: Emagrecimento e condicionamento 🔥
        
        💪 O QUE MEU ALUNO ME CONTOU:
        - Algum problema no corpo? {questionnaire_data.get('has_musculoskeletal_problems', False)} - {questionnaire_data.get('musculoskeletal_details', 'Nada informado')}
        - Problemas respiratórios? {questionnaire_data.get('has_respiratory_problems', False)} - {questionnaire_data.get('respiratory_details', 'Nada informado')}
        - Coração ok? {questionnaire_data.get('has_cardiac_problems', False)} - {questionnaire_data.get('cardiac_details', 'Nada informado')}
        - Já se machucou? {questionnaire_data.get('previous_injuries', [])}
        - Seu nível: {questionnaire_data.get('fitness_level', 'Não informado')}
        - Gosta de quê? {questionnaire_data.get('preferred_exercises', [])}
        - Quer evitar o quê? {questionnaire_data.get('exercises_to_avoid', [])}
        - Onde treina: {"Academia Show!" if workout_type == "gym" else "Em Casa"}
        - FREQUÊNCIA: {days_per_week} dias por semana (fechado!)
        - Tempo por treino: {session_duration} minutos
        - Dias livres: {available_days}
        
        🎯 MINHAS REGRAS DE OURO (não nego):
        1. ⚠️ CRIAR EXATAMENTE {days_per_week} DIAS DE TREINO - NÃO MENOS, NÃO MAIS
        2. 🚫 EXERCÍCIOS POR DIA: MÍNIMO 5, IDEAL 6 - NUNCA 3 OU 4 EXERCÍCIOS!
        3. ⚠️ CADA DIA DEVE TER 5-6 EXERCÍCIOS - CONTE ANTES DE FINALIZAR!
        4. Tipo de local: {"Academia" if workout_type == "gym" else "Casa"}
        4. {"🚫 PROIBIDO: Burpees, Kettlebell, Mountain Climbers, Flexão, TRX, Prancha, exercícios funcionais" if workout_type == "gym" else "🏠 EXERCÍCIOS PARA CASA: Use peso corporal - flexões, agachamentos, pranchas, burpees, etc."}
        {"5. ✅ USAR APENAS: Supino Reto com Barra, Agachamento Livre, Puxada Frontal, Remada Curvada, Desenvolvimento Militar, Rosca Direta, Tríceps Testa" if workout_type == "gym" else ""}
        {"6. 🏋️ EQUIPAMENTOS: Barras, halteres, máquinas de academia - NADA de peso corporal!" if workout_type == "gym" else ""}
        {"7. 📋 DIVISÃO MUSCULAR EQUILIBRADA - SEM REPETIÇÃO!" if workout_type == "gym" else "7. 🏠 DIVISÃO PARA CASA - SEM REPETIÇÃO!"}
        {"   🎯 PARA ACADEMIA - DIVISÃO INTELIGENTE:" if workout_type == "gym" else "   🎯 PARA CASA - DIVISÃO INTELIGENTE:"}
        {"   • 3 dias: Dia 1: Peito+Tríceps | Dia 2: Costas+Bíceps | Dia 3: Pernas+Ombros" if workout_type == "gym" and days_per_week == 3 else ""}
        {"   • 4 dias: Dia 1: Peito+Tríceps | Dia 2: Costas+Bíceps | Dia 3: Pernas | Dia 4: Ombros+Cardio" if workout_type == "gym" and days_per_week == 4 else ""}
        {"   • 5 dias: Dia 1: Peito+Tríceps | Dia 2: Costas+Bíceps | Dia 3: Pernas | Dia 4: Ombros | Dia 5: Cardio/Funcional" if workout_type == "gym" and days_per_week == 5 else ""}
        {"   • 6 dias: Dia 1: Peito+Tríceps | Dia 2: Costas+Bíceps | Dia 3: Pernas | Dia 4: Ombros | Dia 5: Cardio | Dia 6: Funcional/Repetir" if workout_type == "gym" and days_per_week == 6 else ""}
        {"   🏠 CASA - Treino A: Peito+Braços | Treino B: Costas+Braços | Treino C: Pernas | Treino D: Cardio/Core" if workout_type != "gym" else ""}
        {"   ⚠️ REGRA DE OURO: NUNCA REPITA O MESMO FOCO EM DIAS CONSECUTIVOS!" if workout_type == "gym" else ""}
        8. 🏃 CARDIO E ESPORTES ESPECÍFICOS:
        {"   • Se CARDIO nas preferências: 1 dia só cardio (esteira, bike, elíptico)" if has_cardio else ""}
        {"   • Se CORRIDA nas preferências: 1 dia 'Dia de Corrida' (30-45min + alongamento)" if has_running else ""}
        {"   • Se NATAÇÃO nas preferências: 1 dia 'Dia de Natação' (45-60min + exercícios aquáticos)" if has_swimming else ""}
        {"   • Se outros ESPORTES: 1 dia dedicado ao esporte específico" if has_sports else ""}
        {"   • ESPAÇAMENTO: Sempre 4h entre musculação e esporte para evitar fadiga" if has_running or has_swimming or has_sports else ""}
        9. Cuidar das limitações - segurança primeiro! 🛡️
        9. Sempre começar com aquecimento (5-10 min) 
        10. Duração do treino: {session_duration} minutos 
        11. Dias preferidos: {', '.join(available_days) if available_days else 'Qualquer dia da semana'}
        12. 🏃 Se curte corrida/natação: Vou incluir 1 dia específico pro esporte
        13. 🚴 Cardio: {"Esteira, bike ou elíptico no final (5-10 min)" if workout_type == "gym" else "Exercícios cardio com peso corporal"}
        14. 📅 {days_per_week} dias pedidos = {days_per_week} dias entregues!
        15. 🇧🇷 Tudo em português brasileiro - nada de english aqui!
        
        📄 NOVO FORMATO - DOCUMENTO DE ORIENTAÇÕES:
        Ao invés de listar exercícios específicos, vou criar um GUIA DIDÁTICO explicando:
        - Que grupos musculares trabalhar em cada dia
        - Quantos exercícios fazer por grupo
        - Orientações de descanso e execução
        - Dicas de segurança e progression
        - Como organizar esportes (corrida/natação) com espaçamento adequado
        
        📋 EXEMPLO ESTRUTURA PARA {days_per_week} DIAS (LÓGICA CORRETA!):
        
        🎯 DISTRIBUIÇÃO INTELIGENTE - PRIMEIRO TODOS OS MÚSCULOS, DEPOIS REPETE:
        {"• 3 DIAS: Peito+Tríceps → Pernas → Costas+Bíceps (todos os principais cobertos)" if days_per_week == 3 else ""}
        {"• 4 DIAS: Peito+Tríceps → Pernas → Costas+Bíceps → Cardio (ciclo completo + cardio)" if days_per_week == 4 else ""}
        {"• 5 DIAS: Peito+Tríceps → Pernas → Costas+Bíceps → Ombros → Cardio (todos + ombros + cardio)" if days_per_week == 5 else ""}
        {"• 6 DIAS: Peito+Tríceps → Pernas → Costas+Bíceps → Cardio → Peito+Ombros → Costas+Bíceps (repete com variação)" if days_per_week == 6 else ""}
        
        🔄 REGRA DE REPETIÇÃO: SÓ REPITA DEPOIS DE TREINAR TODOS OS GRUPOS PRINCIPAIS!
        📌 GRUPOS PRINCIPAIS OBRIGATÓRIOS: Peito+Tríceps, Pernas, Costas+Bíceps
        📌 GRUPOS COMPLEMENTARES: Ombros, Cardio, Core
        📌 EXEMPLO 6 DIAS: Segunda=Peito+Tríceps → Terça=Pernas → Quarta=Costas+Bíceps → Quinta=Cardio → Sexta=Peito+Ombros → Sábado=Costas+Bíceps
        
        {{
            "plan_name": "Guia de Treino {'Academia' if workout_type == 'gym' else 'Casa'} - {days_per_week} Dias Equilibrados",
            "plan_summary": "Orientações didáticas para {days_per_week} dias de treino SEM REPETIÇÃO, focado em emagrecimento e condicionamento",
            "workout_schedule": [
                {{
                    "day": "{available_days[0] if available_days else 'Dia 1'}",
                    "focus": "{"Peito + Tríceps" if workout_type == "gym" else "Treino A - Peito e Braços"}",
                    "instructions": "Trabalhe o peitoral com 3 exercícios variados (supino, crucifixo, inclinado) e finalize com 2-3 exercícios de tríceps. Use cargas que permitam 8-12 repetições.",
                    "muscle_groups": ["Peitoral maior e menor", "Tríceps braquial", "Deltóide anterior (auxiliar)"],
                    "duration": "{session_duration} minutos",
                    "safety_tips": "Controle sempre a descida do peso. Não trave os cotovelos completamente. Aguarde 4 horas antes de praticar esportes.",
                    "cardio_note": "Finalize com 10-15 minutos de cardio moderado."
                }},
                {
                    "day": "{available_days[1] if len(available_days) > 1 else 'Dia 2'}",
                    "focus": "{"Pernas Completas" if workout_type == "gym" else "Treino B - Pernas e Glúteos"}",
                    "instructions": "Dia completo de pernas! Faça 2-3 exercícios para quadríceps, 2 para posteriores/glúteos e 1 para panturrilhas. Foque na amplitude completa.",
                    "muscle_groups": ["Quadríceps femoral", "Isquiotibiais", "Glúteos (máximo e médio)", "Panturrilhas"],
                    "duration": "{session_duration} minutos",
                    "safety_tips": "Mantenha joelhos alinhados com os pés. Desça controladamente nos agachamentos. Aguarde 4 horas antes de praticar esportes.",
                    "cardio_note": "Cardio leve hoje - apenas 5-10 minutos de caminhada."
                },
                {
                    "day": "{available_days[2] if len(available_days) > 2 else 'Dia 3'}",
                    "focus": "{"Costas + Bíceps" if workout_type == "gym" else "Treino C - Costas e Braços"}",
                    "instructions": "Trabalhe 3 exercícios de costas (puxada, remada curvada, remada baixa) e complete com 2-3 exercícios de bíceps. Priorize a retração das escápulas.",
                    "muscle_groups": ["Latíssimo do dorso", "Rombóides e trapézio", "Bíceps braquial", "Músculos posteriores"],
                    "duration": "{session_duration} minutos",
                    "safety_tips": "Mantenha o core contraído e evite usar impulso nos movimentos. Aguarde 4 horas antes de praticar esportes.",
                    "cardio_note": "Termine com caminhada ou bike por 10-15 minutos."
        
        Retorne APENAS o JSON do plano de 1 dia com medidas exatas."""

                {"," if days_per_week > 5 else ""}
                {'"day": "' + (available_days[5] if len(available_days) > 5 else 'Dia 6') + '", "focus": "Peito + Ombros", "instructions": "Agora que já treinamos todos os grupos principais, podemos repetir com variação! Trabalhe 2-3 exercícios de peito e 2-3 de ombros. Combine peitoral com desenvolvimento dos deltóides.", "muscle_groups": ["Peitoral maior e menor", "Deltóide anterior", "Deltóide medial", "Deltóide posterior"], "duration": "' + str(session_duration) + ' minutos", "safety_tips": "Controle sempre a descida do peso. Evite movimentos bruscos com os ombros. Aguarde 4 horas antes de praticar esportes.", "cardio_note": "Finalize com 10-15 minutos de cardio moderado."}' if days_per_week >= 6 else ""}
                // ⚠️ EXATAMENTE {days_per_week} DIAS - CONTAR ANTES DE FINALIZAR!
                // 🔄 LÓGICA: Dia1=Peito+Tríceps, Dia2=Pernas, Dia3=Costas+Bíceps, Dia4=Cardio, Dia5=Ombros, Dia6=Peito+Ombros (variação)
            ],
            "sports_guidelines": {{
                "general_rule": "ESPAÇAMENTO OBRIGATÓRIO: Sempre aguarde 4 horas entre musculação e esportes para evitar fadiga e risco de lesão.",
                {"running_specific": "CORRIDA: Substitua 1 dia de musculação por treino específico de corrida (30-45min + alongamento). Evite treinar pernas no dia anterior à corrida." if has_running else ""}
                {"swimming_specific": "NATAÇÃO: Substitua 1 dia por treino aquático completo (45-60min). Evite treinar ombros e costas no dia anterior à natação." if has_swimming else ""}
                {"sports_specific": "ESPORTES: Reserve 1 dia específico para sua modalidade favorita. Evite treinar grupos musculares principais do esporte no dia anterior." if has_sports else ""}
                "scheduling_examples": [
                    "Opção 1: Musculação 7h → Esporte após 11h (mesmo dia)",
                    "Opção 2: Esporte pela manhã → Musculação à tarde (4h depois)",  
                    "Opção 3: Dias alternados (mais recomendado para iniciantes)"
                ],
                "recovery_tips": "Hidrate-se bem, faça alongamentos e respeite o descanso entre atividades."
            }},
            "important_notes": [
                "Sempre aqueça 5-10 minutos antes de começar",
                "Hidrate-se bem durante o treino",
                "Respeite suas limitações físicas",
                "Descanse 60-90 segundos entre séries"
            ],
            "progression_tips": "Começe com pesos leves e aumente gradualmente. O importante é manter a constancia!"
        }}
        
        ✅ MINHA CHECAGEM FINAL (Coach Atlas não erra!):
        - ✅ Contar workout_schedule: Tem que ter EXATAMENTE {days_per_week} dias!
        - ✅ REGRA CORRETA: Primeiro treinar todos os grupos principais, DEPOIS pode repetir!
        - 📌 GRUPOS PRINCIPAIS (obrigatórios primeiro): Peito+Tríceps, Pernas, Costas+Bíceps  
        - 🔄 SÓ REPITA depois que todos os principais foram treinados pelo menos 1x
        - ✅ Se tem cardio/corrida/natação, incluir dia específico
        - ✅ Cada dia deve ter instruções claras sobre grupos musculares
        - ✅ Incluir orientações de segurança e espaçamento de 4 horas para esportes
        - ✅ Linguagem simples e didática para facilitar o entendimento
        - 🎯 DISTRIBUIÇÃO CORRETA COM REPETIÇÕES PERMITIDAS:
          {"  3 dias → Peito+Tríceps, Pernas, Costas+Bíceps" if days_per_week == 3 else ""}
          {"  4 dias → Peito+Tríceps, Pernas, Costas+Bíceps, Cardio" if days_per_week == 4 else ""}
          {"  5 dias → Peito+Tríceps, Pernas, Costas+Bíceps, Ombros, Cardio" if days_per_week == 5 else ""}
          {"  6 dias → Peito+Tríceps, Pernas, Costas+Bíceps, Cardio, Peito+Ombros, Costas+Bíceps" if days_per_week == 6 else ""}
        
        {"🏋️ EXERCÍCIOS BÁSICOS OBRIGATÓRIOS (sem complicação):" if workout_type == "gym" else "🏠 LEMBRETE CASA: Use APENAS peso corporal:"}
        {"- Peito: Supino reto, supino inclinado, crucifixo reto" if workout_type == "gym" else "- Peito: Flexões normais/inclinadas/diamante"}
        {"- Costas: Puxada frontal, remada curvada, remada baixa" if workout_type == "gym" else "- Costas: Remada invertida, superman"}
        {"- Pernas: Agachamento livre, leg press, extensão/flexão" if workout_type == "gym" else "- Pernas: Agachamentos, afundos, elevação de panturrilha"}
        {"- Ombros: Desenvolvimento militar, elevação lateral, elevação frontal" if workout_type == "gym" else "- Ombros: Flexão pike, elevação lateral com garrafas"}
        {"- Tríceps: Tríceps testa, tríceps na polia, mergulho" if workout_type == "gym" else "- Tríceps: Flexão diamante, dips na cadeira"}
        {"- Bíceps: Rosca direta, rosca martelo, rosca concentrada" if workout_type == "gym" else "- Bíceps: Rosca com garrafas, rosca isométrica"}
        {"⚠️ NUNCA use: kettlebell, TRX, exercícios funcionais complexos" if workout_type == "gym" else ""}
        {"⚠️ SE CORRIDA/NATAÇÃO: Substitua 1 dia por 'Dia de Corrida' ou 'Dia de Natação'" if workout_type == "gym" else ""}{sports_instruction if workout_type == "gym" else ""}
        💡 FORMATO DE ORIENTAÇÕES DIDÁTICAS:
        - Explicar GRUPOS MUSCULARES ao invés de exercícios específicos
        - Usar linguagem simples: "faça 3 exercícios de peito e 2 de tríceps"
        - Incluir dicas de segurança e espaçamento para esportes
        - Orientar sobre descanso entre séries e intensidade
        - Sempre mencionar o espaçamento de 4 horas entre treino e esportes
        
        🚀 MENSAGEM MOTIVACIONAL DO COACH ATLAS:
        "Bora pra cima! O corpo muda quando você muda a constância 🔥
        O treino de hoje te aproxima da sua melhor versão!
        Disciplina vence motivação - vem comigo! 💪"
        
        IMPORTANTE TÉCNICO:
        1. Retorne APENAS o JSON válido, sem texto adicional antes ou depois
        2. Certifique-se de que todas as strings estão entre aspas duplas
        3. Escape caracteres especiais (aspas, quebras de linha) nas strings
        4. Não inclua comentários ou explicações no JSON
        5. Termine todas as strings e feche todas as chaves corretamente
        """
        
        print(f"[AI_SERVICE] 📝 PROMPT COMPLETO ENVIADO:")
        print(f"[AI_SERVICE] {workout_prompt}")
        print(f"[AI_SERVICE] ===== FIM DO PROMPT =====")
        print(f"[AI_SERVICE] 🚀 Enviando para IA agora...")
        
        try:
            # Gerar resposta usando o serviço de IA
            messages = [{"role": "user", "content": workout_prompt}]
            ai_response = get_ai_response(messages, user_profile)
            
            print(f"[AI_SERVICE] Resposta da IA recebida: {ai_response[:200]}...")
            
            # Validar se a resposta tem o número correto de dias
            try:
                parsed_response = json.loads(ai_response)
                workout_schedule = parsed_response.get('workout_schedule', [])
                actual_days = len(workout_schedule)
                
                print(f"[AI_SERVICE] 📊 Dias solicitados: {days_per_week}, Dias criados: {actual_days}")
                
                if actual_days != days_per_week:
                    print(f"[AI_SERVICE] ⚠️ ERRO: IA criou {actual_days} dias mas usuário quer {days_per_week} dias!")
                    
                    # Tentar corrigir automaticamente
                    if actual_days < days_per_week:
                        print(f"[AI_SERVICE] 🔧 Tentando regenerar com prompt mais específico...")
                        
                        # Prompt mais agressivo
                        strict_prompt = f"""
                        INSTRUÇÃO CRÍTICA: Crie um plano com EXATAMENTE {days_per_week} dias de treino.
                        
                        O usuário quer {days_per_week} dias por semana de treino.
                        Você DEVE criar {days_per_week} entradas no array workout_schedule.
                        
                        Dados: {questionnaire_data}
                        
                        Retorne apenas um JSON válido com {days_per_week} dias no workout_schedule.
                        """
                        
                        strict_messages = [{"role": "user", "content": strict_prompt}]
                        ai_response = get_ai_response(strict_messages, user_profile)
                        
                        print(f"[AI_SERVICE] 🔄 Resposta corrigida: {ai_response[:200]}...")
            
            except json.JSONDecodeError:
                print("[AI_SERVICE] ⚠️ Resposta não é JSON válido, mas retornando assim mesmo")
            
            return ai_response
            
        except Exception as e:
            print(f"Erro ao gerar plano de treino: {str(e)}")
            raise Exception(f"Erro na geração do treino: {str(e)}")

    except Exception as e:
        print(f"Erro geral no serviço de treino: {str(e)}")
        raise Exception(f"Erro no serviço de treino: {str(e)}")
