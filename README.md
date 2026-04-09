# BABFT Engine & Receiver - Documentação Completa e Tutorial Definitivo

Bem-vindo à documentação oficial da **BABFT Engine**. Esta é uma engine completa de construção, renderização, simulação, processamento de dados e recepção HTTP projetada especificamente para o jogo *Build A Boat For Treasure* (Roblox). 

Desenvolvida para automação avançada, a engine concentra sistemas complexos em um único ambiente de execução, funcionando como uma impressora 3D de alta performance. Diferente de scripts simples de auto-build, a BABFT Engine possui seu próprio ecossistema de física, cores, matemática vetorial e até Inteligência Artificial.

---

## Índice
1. [Instalação e Carregamento](#1-instalação-e-carregamento)
2. [O Segredo da Engine: Detecção Automática de Zona](#2-o-segredo-da-engine-detecção-automática-de-zona)
3. [Tutorial 1: O Básico da Construção (Pipeline)](#3-tutorial-1-o-básico-da-construção-pipeline)
4. [Tutorial 2: Manipulação de Cores Avançada (ColorX)](#4-tutorial-2-manipulação-de-cores-avançada-colorx)
5. [Tutorial 3: Geradores Matemáticos e Geometria](#5-tutorial-3-geradores-matemáticos-e-geometria)
6. [Tutorial 4: Motores de Mídia (Imagens e Textos)](#6-tutorial-4-motores-de-mídia-imagens-e-textos)
7. [Tutorial 5: Manipulação Direta (Scale Tool)](#7-tutorial-5-manipulação-direta-scale-tool)
8. [Tutorial 6: Processamento em Lotes (Batch)](#8-tutorial-6-processamento-em-lotes-batch)
9. [Tutorial 7: Comunicação Externa (HTTP & Parser)](#9-tutorial-7-comunicação-externa-http--parser)
10. [Tutorial 8: Inteligência Artificial (Experimental)](#10-tutorial-8-inteligência-artificial-experimental)
11. [Criptografia e Segurança](#11-criptografia-e-segurança)
12. [Boas Práticas e Dicas de Otimização](#12-boas-práticas-e-dicas-de-otimização)

---

## 1. Instalação e Carregamento

A engine é consolidada em um único arquivo de distribuição (Bundle). Para utilizá-la, você precisa de um executor Roblox com suporte a requisições web e funções de ambiente (`loadstring`).

Abra o seu executor e rode o seguinte código:

```lua
-- Carrega a engine diretamente do repositório oficial
local BABFT = loadstring(game:HttpGet("https://raw.githubusercontent.com/plushchaosredholder/RednNickProjectRoblox/refs/heads/main/BABFT_Bundle.lua"))()

-- A engine também se auto-injeta no ambiente global.
-- Isso significa que você pode usar 'BABFT' em qualquer aba do seu executor!
print("Engine carregada com sucesso!")
```

---

## 2. O Segredo da Engine: Detecção Automática de Zona

A maior dificuldade em criar scripts para o BABFT é calcular onde a sua base (Plot) está no mapa. A BABFT Engine resolve isso de forma invisível.

**Como funciona a mágica:**
Quando você manda a engine construir algo, ela verifica a cor do seu time atual (`LocalPlayer.TeamColor`). Com base nessa cor, ela varre o mapa do jogo, encontra a sua "Zone" (ex: `WhiteZone`, `MagentaZone`), e calcula matematicamente o centro exato da sua base.

**O que isso significa para você?**
Você **não precisa** usar coordenadas globais complexas (ex: `CFrame.new(5043, 10, -200)`). Se você mandar a engine construir um bloco na posição `(0, 5, 0)`, ela vai colocar esse bloco exatamente no meio da sua base, 5 studs acima do chão. Se você mudar de time, a engine recalcula tudo instantaneamente.

---

## 3. Tutorial 1: O Básico da Construção (Pipeline)

O `Pipeline` é o coração da engine. Ele é responsável por spawnar os blocos de forma segura, sem colidir com o mapa, e depois puxá-los para a posição final.

### Estrutura de um Bloco
Para construir, você precisa criar uma tabela (lista) de blocos. Cada bloco pode ter as seguintes propriedades:

```lua
local meuBloco = {
    Block = "PlasticBlock",          -- Nome do bloco no jogo (Padrão: PlasticBlock)
    Position = Vector3.new(0, 10, 0),-- Posição relativa ao centro da sua plot
    Size = Vector3.new(4, 4, 4),     -- Tamanho do bloco
    Color = Color3.fromRGB(255, 0, 0)-- Cor do bloco (Vermelho)
}
```

### Construindo na Prática
Vamos criar uma parede simples usando o Pipeline:

```lua
local parede = {}

-- Criando 5 blocos empilhados
for i = 1, 5 do
    table.insert(parede, {
        Block = "NeonBlock",
        Position = Vector3.new(0, i * 2, 0), -- Sobe 2 studs a cada bloco
        Size = Vector3.new(10, 2, 2),
        Color = Color3.fromRGB(0, 255, 0)
    })
end

-- Configurações do Pipeline (Opcional, mas recomendado entender)
local config = {
    SpawnHeight = 96000,  -- Spawna os blocos no céu para não bugar a física
    UseScaleMove = true,  -- Usa a Scale Tool para mover pro chão
    UseBatchPaint = true, -- Pinta tudo de uma vez sem lag
    BatchSize = 150       -- Processa 150 blocos por vez
}

-- Manda construir!
BABFT.Pipeline.run(parede, config)
```

---

## 4. Tutorial 2: Manipulação de Cores Avançada (ColorX)

Esqueça o `Color3.new` básico. O módulo `BABFT.cx` (ColorX) é um motor de cores profissional.

### Trabalhando com Hexadecimal e HSV
```lua
local cx = BABFT.cx

-- Pegou uma cor hexadecimal da internet? Use direto:
local corHex = cx.fromHex("#00FFCC")

-- Quer trabalhar com Matiz, Saturação e Brilho?
local corHSV = cx.fromHSV(0.5, 1, 1) -- Ciano brilhante
```

### Criando Gradientes e Arco-íris
O `ColorX` pode calcular cores intermediárias perfeitamente.

```lua
local cx = BABFT.cx
local blocos = {}

-- Vamos fazer uma fileira de 20 blocos com um gradiente do Vermelho pro Azul
local coresGradiente = {
    Color3.fromRGB(255, 0, 0),   -- Vermelho
    Color3.fromRGB(0, 255, 0),   -- Verde
    Color3.fromRGB(0, 0, 255)    -- Azul
}

for i = 1, 20 do
    -- O 't' vai de 0.0 até 1.0
    local t = i / 20 
    local corCalculada = cx.gradient(coresGradiente, t)
    
    table.insert(blocos, {
        Block = "GlassBlock",
        Position = Vector3.new(i * 2, 5, 0),
        Size = Vector3.new(2, 2, 2),
        Color = corCalculada
    })
end

BABFT.Pipeline.run(blocos)
```

### Efeitos de Cor
```lua
local corBase = cx.fromHex("#FF0000")
local corEscura = cx.darken(corBase, 0.5)  -- Escurece 50%
local corInvertida = cx.invert(corBase)    -- Retorna Ciano (Negativo)
local corMisturada = cx.blend(corBase, Color3.new(0,0,1), "add") -- Mescla cores
```

---

## 5. Tutorial 3: Geradores Matemáticos e Geometria

Não quer calcular posições na mão? A engine faz isso por você.

### Gerando uma Esfera
```lua
-- Parâmetros: Raio (30), Resolução (16), Material ("GlassBlock")
local esfera = BABFT.Generators.sphere(30, 16, "GlassBlock")

-- A engine vai centralizar a esfera na sua plot automaticamente!
BABFT.Pipeline.run(esfera)
```

### Gerando Terreno (Noise)
Cria montanhas e vales usando algoritmos de ruído procedural.
```lua
-- Parâmetros: Largura, Profundidade, Escala do Ruído, Altura Máxima, Material
local terreno = BABFT.Generators.noiseTerrain(50, 50, 0.05, 20, "GrassBlock")
BABFT.Pipeline.run(terreno)
```

### Desenhando Linhas (Lasers, Fios)
```lua
-- Liga o ponto A ao ponto B com um bloco esticado
local pontoA = Vector3.new(-50, 10, -50)
local pontoB = Vector3.new(50, 100, 50)

local laser = BABFT.Geometry.line(pontoA, pontoB, 1.5, "NeonBlock")
BABFT.Pipeline.run({laser}) -- Coloque entre chaves {} pois é um único bloco
```

---

## 6. Tutorial 4: Motores de Mídia (Imagens e Textos)

### Escrevendo Textos 3D
O `CharEngine` converte strings em blocos físicos.
```lua
local configTexto = {
    blockSize = 2,
    blockName = "NeonBlock",
    color = Color3.fromRGB(255, 255, 0) -- Amarelo
}

-- Gera a palavra "ROBLOX"
local texto = BABFT.CharEngine.render("ROBLOX", configTexto)
BABFT.Pipeline.run(texto)
```

### Importando Pixel Art 
```lua
-- Baixa a imagem da internet e converte em blocos
local imgData = BABFT.RemoteCompute.processImage("https://i.imgur.com/suaimagem.png", 64)

-- Converte os pixels para o formato do Pipeline
local pixelArt = BABFT.ImageEngine.toBlueprint(imgData, { blockSize = 1 })
BABFT.Pipeline.run(pixelArt)
```

---

## 7. Tutorial 5: Manipulação Direta (Scale Tool)

Às vezes você não quer construir algo novo, mas sim modificar algo que já está no mapa. O módulo `BABFT.Scale` facilita isso utilizando a ferramenta de escala do jogo.

```lua
-- Encontra um bloco na sua base (Exemplo: O primeiro bloco de plástico)
local meuBloco = workspace.Blocks[game.Players.LocalPlayer.Name]:FindFirstChild("PlasticBlock")

if meuBloco then
    local novaPosicao = CFrame.new(0, 100, 0) -- Joga o bloco 100 studs pra cima
    local novoTamanho = Vector3.new(20, 1, 20) -- Transforma numa plataforma gigante
    
    -- Move e redimensiona instantaneamente!
    BABFT.Scale.moveTo(meuBloco, novaPosicao, novoTamanho)
end
```

---

## 8. Tutorial 6: Processamento em Lotes (Batch)

Se você tentar rodar um loop `for` com 10.000 repetições no Roblox, o jogo vai congelar (Crash). O `BABFT.Batch` resolve isso criando "Workers" (trabalhadores) que executam tarefas aos poucos.

```lua
-- Cria um gerenciador de fila com 50 trabalhadores simultâneos
local meuBatch = BABFT.Batch.new({ mode = "queue", workers = 50 })

-- Adiciona 5000 tarefas pesadas na fila
for i = 1, 5000 do
    meuBatch:add(function()
        -- Coloque códigos pesados aqui (ex: InvokeServer, cálculos matemáticos)
        local calculo = math.sqrt(i) * math.noise(i, i, i)
    end)
end

-- Inicia o processamento em segundo plano sem travar o jogo!
meuBatch:run()

-- Se precisar cancelar tudo no meio do caminho:
-- meuBatch:stopWorkers()
```

---

## 9. Tutorial 7: Comunicação Externa (HTTP & Parser)

A BABFT Engine pode funcionar como um "Receiver" (Receptor). Isso significa que você pode ter um servidor em Python ou Node.js gerando construções, e o Roblox apenas recebe e constrói.

### Lendo um JSON da Internet
O módulo `Parser` faz todo o trabalho duro de converter JSON para blocos.

```lua
local url = "https://seusite.com/api/minha-construcao.json"

-- O fetchAndParse baixa o JSON, converte, e se o segundo argumento for 'true',
-- ele já manda pro Pipeline construir automaticamente!
local blocos, erro = BABFT.Parser.fetchAndParse(url, true)

if erro then
    warn("Erro ao baixar a construção:", erro)
else
    print("Construção recebida com sucesso! Total de blocos:", #blocos)
end
```

---

## 10. Tutorial 8: Inteligência Artificial (Experimental)

A engine possui integração nativa com IA. Você pode conversar com a IA ou pedir para ela programar construções para você.

⚠️ **Aviso:** A IA pode gerar códigos com erros de sintaxe. Use com cautela.

### Conversando com a IA
```lua
local resposta = BABFT.AI.ask("Me dê uma ideia de barco para construir no BABFT.")

if resposta then
    print("=== O que a IA pensou ===")
    print(resposta.reasoning)
    
    print("=== Resposta Final ===")
    print(resposta.content)
end
```

### Deixando a IA programar o seu jogo
O comando `execute` pede para a IA escrever um script em Luau e o roda automaticamente no seu executor!

```lua
local prompt = "Crie um script usando a BABFT Engine que gera um cubo gigante de NeonBlock vermelho no meio da minha plot."

local sucesso, mensagem = BABFT.AI.execute(prompt)

if sucesso then
    print("A IA escreveu e executou o código com sucesso!")
else
    warn("A IA falhou:", mensagem)
end
```

---

## 11. Criptografia e Segurança

Se você estiver usando a engine conectada a um servidor externo, saiba que toda a comunicação é **100% Criptografada**.

O módulo interno intercepta os dados JSON e os transforma em uma string ofuscada usando uma chave criptografada e substituição de caracteres por meio de criptografia criada pelos desenvolvedores do projeto.

Isso impede que "Sniffers" consigam ler o que está sendo enviado ou recebido, protegendo o código fonte do seu servidor e a lógica da sua construção.

---

## 12. Boas Práticas e Dicas de Otimização

1. **Pré-Construção Oculta:** O `Pipeline` joga os blocos na camada `980000` por um motivo: Se você spawnar blocos direto no chão, eles vão colidir com o seu personagem, com outras construções e causar lag de física. Deixe o Pipeline fazer o trabalho dele no céu e puxar para o chão depois.
2. **Dimensionamento de Lotes:** O `BatchSize` padrão é 150. Se a sua internet for lenta ou o servidor do Roblox estiver travando, diminua para 25 ou 50. Se você tiver um PC muito forte, pode tentar aumentar para 450 ou 750 (Mas depende da conexão com o servidor do Roblox)
3. **Mapeamento de Cores:** Utilize estritamente valores `Color3.fromRGB` ou o módulo `BABFT.cx`. Todo o motor de cores, Greedy Meshing e a Pipeline baseiam as equações de resolução em matrizes RGB.
4. **Limpeza de Cache:** Se a engine começar a ficar lenta após muitas construções, você pode forçar a limpeza da memória rodando o comando `BABFT.Cleanup.run()`.
5. **Atualizações Core:** O motor é carregado via raw do GitHub. Certifique-se de executar sempre a build de produção mais atual do repositório para incorporar automaticamente correções de adaptadores e patches do anti-cheat nativo do Roblox.
