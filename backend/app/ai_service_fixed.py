    
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=2000
        )
        
        print(f"[DEBUG] OpenAI respondeu com sucesso")
        
        content = response.choices[0].message.content
        print(f"[DEBUG] Content length: {len(content)}")
        
        try:
            result = json.loads(content)
            print(f"[DEBUG] JSON parseado com sucesso. Keys: {list(result.keys())}")
            
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

