from PIL import Image

def gerar_tileset_e_mapa(imagem_path, largura_tile=8, altura_tile=8):
    try:
        # 1. Abre a imagem original
        img = Image.open(imagem_path).convert('RGB')
        largura, altura = img.size
        print(f"Processando imagem de {largura}x{altura} pixels...")
    except FileNotFoundError:
        print(f"Erro: O arquivo '{imagem_path}' não foi encontrado.")
        return

    # Validar se a resolução é divisível por 8
    if largura % largura_tile != 0 or altura % altura_tile != 0:
        print("Aviso: As dimensões da imagem não são múltiplas de 8. As bordas podem ser cortadas.")

    tiles_unicos = [] # Vai guardar a informação de cor de cada bloco único
    mapa = []         # Vai guardar o ID de cada bloco correspondente à tela inteira

    # 2. Percorrer a imagem inteira, fatiando de 8 em 8 pixels
    for y in range(0, altura, altura_tile):
        linha_mapa = []
        for x in range(0, largura, largura_tile):
            # Definir as coordenadas do corte (Esquerda, Cima, Direita, Baixo)
            box = (x, y, x + largura_tile, y + altura_tile)
            tile_img = img.crop(box)
            
            # Converter os pixels do bloco em uma lista imutável (tupla) para podermos comparar
            tile_dados = tuple(tile_img.getdata())
            
            # 3. Verifica se este bloco é novo ou se já vimos um idêntico antes
            if tile_dados not in tiles_unicos:
                tiles_unicos.append(tile_dados) # É novo! Adiciona à lista de carimbos
            
            # Descobre qual é o número (ID) deste bloco na nossa lista
            tile_id = tiles_unicos.index(tile_dados)
            linha_mapa.append(tile_id)
            
        mapa.append(linha_mapa)

    # ==========================================
    # SALVANDO O TILESET (A Imagem dos Carimbos)
    # ==========================================
    # Cria uma nova imagem comprida: a largura é o nº de blocos * 8, e a altura é 8.
    largura_tileset = len(tiles_unicos) * largura_tile
    img_tileset = Image.new('RGB', (largura_tileset, altura_tile))
    
    for i, tile_dados in enumerate(tiles_unicos):
        # Recria a imagem 8x8 a partir dos dados gravados
        tile_temp = Image.new('RGB', (largura_tile, altura_tile))
        tile_temp.putdata(tile_dados)
        # Cola o bloquinho 8x8 lado a lado na imagem final do tileset
        img_tileset.paste(tile_temp, (i * largura_tile, 0))
        
    img_tileset.save("tileset_gerado.png")
    print(f"\n[SUCESSO] Tileset gerado com {len(tiles_unicos)} blocos únicos!")
    print("Salvo como: 'tileset_gerado.png'")

    # ==========================================
    # SALVANDO O TILEMAP (O Mapa da Tela em CSV)
    # ==========================================
    with open("tilemap_gerado.csv", "w") as f:
        for linha in mapa:
            # Pega a lista de IDs de uma linha e junta tudo separado por vírgula
            linha_str = ",".join(str(id) for id in linha)
            f.write(linha_str + "\n")
    
    print("[SUCESSO] Tilemap gerado!")
    print("Salvo como: 'tilemap_gerado.csv'\n")

# Executa a função passando o nome do arquivo que você enviou
gerar_tileset_e_mapa(r"C:\Users\João\Documents\UNICAMP\MC613\VGA\VGA\Sprites.png")