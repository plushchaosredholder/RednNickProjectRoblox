# BABFT Engine & Receiver - Documentacao Completa

Uma engine completa de construcao, renderizacao, simulacao, processamento de dados e recepcao HTTP dentro do Build A Boat For Treasure (Roblox). Desenvolvida para automacao avancada, a engine concentra sistemas complexos em um unico ambiente de execucao, funcionando como uma impressora 3D de alta performance.

## Instalacao e Carregamento

A engine e consolidada em um unico arquivo de distribuicao. Para utiliza-la, voce precisa de um executor Roblox com suporte a requisicoes web e funcoes de ambiente (`loadstring`).

```lua
local BABFT = loadstring(game:HttpGet("https://raw.githubusercontent.com/plushchaosredholder/RednNickProjectRoblox/refs/heads/main/BABFT_Bundle.lua"))()
```
*Este comando carrega simultaneamente todos os modulos: Pipeline, Batch, Generators, Color Tools, Motores 3D, IA e Utilitarios.*

## Estrutura de Dados de Bloco

O modulo base da engine compreende blocos atraves de tabelas Lua padronizadas. Cada bloco que passa pelo sistema deve seguir este formato:

| Campo | Tipo | Descricao |
|---|---|---|
| Block | string | Nome exato da ferramenta/bloco no jogo (ex: "PlasticBlock") |
| CFrame | CFrame | Coordenada espacial absoluta e rotacao do bloco |
| Size | Vector3 | Escala tridimensional nos eixos X, Y e Z |
| Color | Color3 | Cor aplicada via pintura (RGB) |

**Exemplo de declaracao de bloco:**
```lua
local bloco = {
    Block = "PlasticBlock",
    CFrame = CFrame.new(0, 5, 0),
    Size = Vector3.new(1, 1, 1),
    Color = Color3.fromRGB(255, 0, 0)
}
```
*(Nota: Se omitir CFrame, Size ou Color, a engine usará padrões inteligentes e centralizará o bloco na sua plot automaticamente).*

## O Pipeline Obrigatorio (High Layer Build System)

O funcionamento da engine depende estritamente de um fluxo sequencial (Pipeline) para contornar as limitacoes fisicas do Roblox e evitar crash no servidor. Constrói blocos de forma assíncrona, aplicando escala e cor de forma segura.

### Os 7 Passos do Pipeline Interno
 1. **Spawn:** Todos os blocos sao gerados na coordenada limite de altura (SPAWN_HEIGHT = 980000) para evitar interferencia fisica ou colisao com o cenario.
 2. **Snapshot:** A engine tira uma leitura em tempo real da hierarquia do Workspace.
 3. **Detect:** O sistema compara o Workspace com o Snapshot para isolar novos blocos gerados.
 4. **Match:** Associa os blocos isolados as instrucoes da tabela, usando a posicao de spawn como chave.
 5. **Scale & Move:** Utiliza `ScalingTool.RF` para redimensionar e teletransportar cada bloco para sua coordenada final.
 6. **Paint:** Aplica as texturas e cores finais em lote (Batching) atraves da `PaintingTool.RF`.
 7. **Cleanup:** Aciona o Garbage Collector para deletar dados temporarios e liberar memoria do cliente.

### Como Executar o Pipeline
```lua
local meusBlocos = {bloco1, bloco2, bloco3}

local config = {
    SpawnHeight = 980000,    -- Altura inicial da pre-construcao
    UseHighLayer = true,     -- Ativa fluxo otimizado
    UseBatchPaint = true,    -- Pinta blocos em lotes
    UseScaleMove = true,     -- Aplica escala antes de mover
    BatchSize = 150,         -- Quantidade de blocos processados por ciclo
    OnComplete = function()
        print("Construcao finalizada com sucesso!")
    end
}

BABFT.Pipeline.run(meusBlocos, config)
```

## Modulos e Engines Disponiveis

A arquitetura e dividida em modulos especificos, acessados diretamente atraves da variavel `BABFT`.

### Inteligencia Artificial (BABFT.AI)
Motor de IA integrado que se comunica de forma criptografada com o Supabase/Pollinations para gerar e executar codigos dinamicamente.
```lua
-- Perguntar algo para a IA
local resposta = BABFT.AI.ask("Como fazer um circulo?")
print(resposta.content, resposta.reasoning)

-- Pedir para a IA programar e executar no jogo automaticamente!
BABFT.AI.execute("Crie uma esfera de vidro vermelha no meio da minha plot")
```

### Motores de Importacao e Processamento
 * **BABFT.ImageEngine**: Download de imagens via URL. Analisa os pixels (RGB) e converte a matriz bidimensional em instrucoes espaciais de construcao.
 * **BABFT.OBJEngine**: Interpretador de arquivos .OBJ. Le listas de vertices/faces e aplica algoritmos de voxelizacao para transformar malhas 3D em blocos.
 * **BABFT.MeshEngine**: Amostragem (sampling) de instâncias MeshPart do Roblox, convertendo-as em voxels.
 * **BABFT.CharEngine**: Motor de renderizacao tipografica. Transforma matrizes de fontes em caracteres Unicode renderizados fisicamente.
 * **BABFT.BabftFile**: Sistema de leitura/gravacao proprietario (.babft) para salvar e carregar construcoes inteiras.
 * **BABFT.Parser**: Leitor universal de JSON. Converte arrays, dicionarios e matrizes externas para o formato nativo da engine.

### Batch - Processamento de Lotes
O sistema `BABFT.Batch` gerencia requisicoes e funcoes pesadas em lotes para evitar que o cliente ou o servidor congelem (modos: queue, instant, chunked, adaptive).
```lua
local meuBatch = BABFT.Batch.new({ mode = "queue", workers = 100 })

for i = 1, 500 do
    meuBatch:add(function()
        print("Executando tarefa", i)
    end)
end

meuBatch:run()
-- meuBatch:stopWorkers() -- Para interrupcao forcada
```

### Geradores de Formas (Generators & Geometry)
Funcoes pre-programadas para evitar calculos matematicos e vetoriais complexos manuais. Nao e necessario especificar posicoes, a engine usa o `DefineCenter` para centralizar na sua plot automaticamente.
```lua
-- Define um centro customizado (Opcional, o padrao e o meio da sua plot)
-- BABFT.DefineCenter(Vector3.new(100, 0, 100))

-- Gerar Esfera Oca
local esfera = BABFT.Generators.sphere(30, 16, "GlassBlock")
BABFT.Pipeline.run(esfera)

-- Gerar Terreno com Noise Otimizado
local terreno = BABFT.Generators.noiseTerrain(30, 30, 0.1, 15, "GrassBlock")
BABFT.Pipeline.run(terreno)

-- Gerar Linha/Laser/Fio entre dois pontos espaciais
local p1 = Vector3.new(0, 10, 0)
local p2 = Vector3.new(100, 50, 100)
local linha = BABFT.Geometry.line(p1, p2, 2, "NeonBlock")
BABFT.Pipeline.run({linha})
```

### Movimentacao Direta (BABFT.Scale)
Permite mover e redimensionar blocos ja existentes no mapa instantaneamente usando a Scaling Tool.
```lua
local meuBloco = workspace.WhiteZone.PlasticBlock
BABFT.Scale.moveTo(meuBloco, CFrame.new(0, 50, 0), Vector3.new(5, 5, 5))
```

### Color Tools (BABFT.cx / ColorX)
Motor avancado de espaço de cores, suportando transicoes, compressoes, HSV e manipulacoes diretas.
```lua
local cx = BABFT.cx -- ou BABFT.ColorX

local corHex = cx.fromHex("#FF00FF")           -- Retorna Color3
print(cx.toHex(Color3.new(1, 0, 0)))           -- Retorna String "#FF0000"

local corEscura = cx.darken(corHex, 0.5)       -- Escurece a cor em 50%
local corClara = cx.lighten(corHex, 0.5)       -- Clareia a cor em 50%
local corMisturada = cx.blend(Color3.new(1,0,0), Color3.new(0,0,1), "add")

-- Suporte a HSV e Gradientes
local corHSV = cx.fromHSV(0.5, 1, 1)
local gradiente = cx.gradient({Color3.new(1,0,0), Color3.new(0,0,1)}, 0.5) -- Retorna roxo
```

### Otimizacao Estrutural, Computacao e ML
 * **BABFT.Compressor**: Algoritmo rigoroso usando "Greedy Meshing" (aglutinacao de blocos) e "Interior Culling" (remocao de blocos invisiveis no núcleo) para economizar limites de memoria.
 * **BABFT.ToolAdapter**: Falsificacao de ferramentas. Envia RemoteFunctions como pintura, escala e bind sem o avatar estar equipando os itens.
 * **BABFT.np / BABFT.tensor**: Bibliotecas internas baseadas em Numpy para operacoes com matrizes vetoriais pesadas e calculos estatisticos.
 * **BABFT.ML / BABFT.RemoteCompute**: Algoritmos de Machine Learning e delegacao de calculos via HTTP para servidores externos (Supabase). **Toda a comunicacao externa e 100% criptografada** com chaves XOR e substituicao de simbolos para proteger o codigo fonte.

## Receiver - Sistema de Recepcao HTTP
O modulo Receiver permite que a engine atue como um cliente de escuta, recebendo instrucoes de construcao (JSON) de um servidor ou endpoint externo de forma continua, convertendo-as diretamente em blocos.

**Exemplo de Polling HTTP para integracao externa (Simplificado com Parser):**
```lua
local URL = "https://seusite.com/api/build"

task.spawn(function()
    while true do
        -- Baixa o JSON da URL, converte para blocos e ja constroi automaticamente!
        local blocos, erro = BABFT.Parser.fetchAndParse(URL, true)
        
        if erro then
            warn("Aguardando novas instrucoes...")
        else
            print("Construcao recebida e processada via HTTP!")
        end
        
        task.wait(5)
    end
end)
```

**Formato do JSON esperado pelo endpoint:**
```json
[
  {
    "Block": "PlasticBlock",
    "Position": [0, 5, 0],
    "Rotation": [0, 90, 0],
    "Size": [2, 2, 2],
    "Color": [255, 0, 0]
  }
]
```
*Notas do Payload: Position e Size estao em studs. Rotation esta em graus. Color esta no espectro RGB 0–255. Se omitidos, a engine preenche com os padroes.*

## Funcoes de Utilitarios (Utilities)
A engine contem metodos nativos para tratamento pre e pos construcao:
 * `BABFT.DefineCenter(Vector3)`: Define a origem global para construcoes que nao possuem CFrame especificado.
 * `BABFT.HTTP.get(url)`: Wrapper seguro que tenta usar `HttpGetAsync` e faz fallback para `HttpGet`.
 * `BABFT.Crypto`: Modulo de criptografia bidirecional para ofuscar payloads HTTP.
 * `clear()`: Esvazia o cache da pipeline, destroi a pasta temporaria e reinicia a integridade da Store de dados do cliente.

## Dicas e Boas Praticas de Uso
 1. **Pre-Construcao Oculta:** Recomendamos sempre construir o projeto inicialmente usando o fluxo padrao da Pipeline (que joga os blocos na camada 980.000). Isso previne interrupcoes de fisica e colisoes durante a execucao.
 2. **Dimensionamento de Lotes (Batches):** Para construcoes densas, regule a configuracao `BatchSize` da Pipeline entre 50 e 150 blocos por vez. Valores superiores a isso podem exceder o tempo limite de processamento de pacotes do servidor, causando disconnect.
 3. **Mapeamento de Cores:** Utilize estritamente valores `Color3.fromRGB` ou o modulo `BABFT.cx`. Todo o motor de cores, Greedy Meshing e a Pipeline baseiam as equacoes de resolucao em matrizes RGB.
 4. **Atualizacoes Core:** O motor e carregado via raw do GitHub. Certifique-se de executar sempre a build de producao mais atual do repositorio para incorporar automaticamente correcoes de adaptadores e patches do anti-cheat nativo do Roblox.
