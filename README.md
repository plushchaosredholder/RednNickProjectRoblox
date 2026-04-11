# BABFT Engine - Documentação Oficial

Bem-vindo à documentação completa e detalhada da BABFT Engine. Este documento descreve todas as bibliotecas, módulos, funções e a sintaxe simplificada (DSL) disponível para uso. A engine é injetada globalmente e pode ser acessada através da variável `_G.BABFT`.

---

## 1. Inicialização (Loader)

Para carregar a engine na memória, utilize o script abaixo. Ele fará o download necessário e armazenará os dados em cache na memória do jogo para carregamentos subsequentes mais rápidos.

```lua
local l,c,s,g=string.char,table.concat,tostring,game;local function d(t)local r={}for i,v in ipairs(t)do r[i]=l(v)end return c(r)end;local rs=g:GetService(d({82,101,112,108,105,99,97,116,101,100,83,116,111,114,97,103,101}));local n=d({66,65,66,70,84});local v=rs:FindFirstChild(n);if not v then v=Instance.new(d({83,116,114,105,110,103,86,97,108,117,101}));v.Name=n;v.Value=g:HttpGet(d({104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,112,108,117,115,104,99,104,97,111,115,114,101,100,104,111,108,100,101,114,47,82,101,100,110,78,105,99,107,80,114,111,106,101,99,116,82,111,98,108,111,120,47,114,101,102,115,47,104,101,97,100,115,47,109,97,105,110,47,66,65,66,70,84,46,108,117,97}));v.Parent=rs;end;local f,e=loadstring(v.Value);if f then f() else warn(e) end
```

---

## 2. Arquitetura da Engine

A engine é dividida em múltiplos módulos (Libraries), cada um responsável por uma área específica de manipulação do ambiente. Todos os módulos estão contidos dentro da tabela principal `_G.BABFT`.

### 2.1. Core (`_G.BABFT.Core`)
O módulo Core lida com as informações fundamentais do jogador e do mundo.

*   **`Core.getPlot()`**
    *   **Retorno:** `Instance` (Model) ou `nil`.
    *   **Descrição:** Varre o workspace para encontrar a base (plot) que pertence ao jogador local. Retorna o modelo da base se encontrado.
*   **`Core.getCenter()`**
    *   **Retorno:** `CFrame`.
    *   **Descrição:** Calcula e retorna o CFrame exato do centro da base do jogador. Usado como ponto de referência zero (0,0,0) para todas as construções relativas.
*   **`Core.getPlayer()`**
    *   **Retorno:** `Player`.
    *   **Descrição:** Retorna a instância do jogador local.

### 2.2. Blocks (`_G.BABFT.Blocks`)
O módulo Blocks é responsável pela instanciação e manipulação direta de blocos.

*   **`Blocks.place(blockName: string, cframe: CFrame)`**
    *   **Parâmetros:** `blockName` (Nome do bloco no jogo), `cframe` (Posição e rotação).
    *   **Descrição:** Instancia um novo bloco no mundo.
*   **`Blocks.color(block: Instance, color: Color3)`**
    *   **Parâmetros:** `block` (Instância do bloco), `color` (Cor em formato Color3).
    *   **Descrição:** Altera a cor de um bloco existente.
*   **`Blocks.scale(block: Instance, scale: Vector3)`**
    *   **Parâmetros:** `block` (Instância do bloco), `scale` (Tamanho em Vector3).
    *   **Descrição:** Redimensiona o bloco nos eixos X, Y e Z.
*   **`Blocks.destroy(block: Instance)`**
    *   **Parâmetros:** `block` (Instância do bloco).
    *   **Descrição:** Remove o bloco do workspace.

### 2.3. Properties (`_G.BABFT.Properties`)
Gerencia as propriedades físicas e visuais avançadas dos objetos.

*   **`Properties.setTransparency(block: Instance, transparency: number)`**
    *   **Parâmetros:** `block` (Instância), `transparency` (Número de 0 a 1).
    *   **Descrição:** Define o nível de transparência do bloco.
*   **`Properties.setCollision(block: Instance, canCollide: boolean)`**
    *   **Parâmetros:** `block` (Instância), `canCollide` (Booleano).
    *   **Descrição:** Define se o bloco tem colisão física com outros objetos e jogadores.
*   **`Properties.setAnchored(block: Instance, anchored: boolean)`**
    *   **Parâmetros:** `block` (Instância), `anchored` (Booleano).
    *   **Descrição:** Define se o bloco é afetado pela gravidade e física do jogo.
*   **`Properties.setMaterial(block: Instance, material: Enum.Material)`**
    *   **Parâmetros:** `block` (Instância), `material` (Enum do Roblox).
    *   **Descrição:** Altera a textura e o material físico do bloco.

### 2.4. Movement (`_G.BABFT.Movement`)
Lida com a translação e rotação de objetos já existentes.

*   **`Movement.moveTo(block: Instance, cframe: CFrame)`**
    *   **Parâmetros:** `block` (Instância), `cframe` (Novo CFrame).
    *   **Descrição:** Move instantaneamente o bloco para a nova posição e rotação.
*   **`Movement.rotate(block: Instance, rotation: Vector3)`**
    *   **Parâmetros:** `block` (Instância), `rotation` (Ângulos em graus).
    *   **Descrição:** Aplica uma rotação relativa ao bloco atual.
*   **`Movement.tween(block: Instance, targetCFrame: CFrame, time: number)`**
    *   **Parâmetros:** `block` (Instância), `targetCFrame` (Destino), `time` (Duração em segundos).
    *   **Descrição:** Move o bloco suavemente de sua posição atual para o destino.

### 2.5. Tools (`_G.BABFT.Tools`)
Controla as ferramentas do inventário do jogador.

*   **`Tools.equip(toolName: string)`**
    *   **Parâmetros:** `toolName` (Nome da ferramenta, ex: "ScalingTool").
    *   **Descrição:** Procura a ferramenta na mochila do jogador e a equipa no personagem.
*   **`Tools.unequipAll()`**
    *   **Descrição:** Remove qualquer ferramenta atualmente equipada nas mãos do personagem e a devolve para a mochila.
*   **`Tools.getEquipped()`**
    *   **Retorno:** `Instance` (Tool) ou `nil`.
    *   **Descrição:** Retorna a ferramenta que o jogador está segurando no momento.

### 2.6. AI (`_G.BABFT.AI`)
Módulo de processamento de linguagem natural e geração de código.

*   **`AI.ask(prompt: string, simulate: boolean)`**
    *   **Parâmetros:** `prompt` (Texto da pergunta), `simulate` (Booleano opcional para simular digitação).
    *   **Retorno:** Tabela contendo a resposta e o raciocínio (Chain of Thought).
    *   **Descrição:** Envia uma requisição para a IA. O módulo gerencia automaticamente um histórico das últimas 10 mensagens (5 interações) e anexa os dados do jogador (UserId, Name, DisplayName) ao prompt para fornecer contexto.
*   **`AI.execute(prompt: string)`**
    *   **Parâmetros:** `prompt` (Comando em linguagem natural).
    *   **Retorno:** Booleano (sucesso), String (mensagem).
    *   **Descrição:** Envia o prompt para a IA, extrai qualquer bloco de código Luau retornado na resposta e o executa imediatamente no ambiente do jogo usando `loadstring`.

### 2.7. Polyglot (`_G.BABFT.Polyglot`)
Sistema de execução de múltiplas linguagens de programação.

*   **`Polyglot.execute(code: string, lang: string)`**
    *   **Parâmetros:** `code` (Código fonte), `lang` (Linguagem, ex: "Python", "C", "Lua").
    *   **Retorno:** Resultado da execução.
    *   **Descrição:** Se a linguagem for Lua/Luau, executa nativamente. Se for Python ou C, envia o código para a IA atuar como um transpilador, convertendo a lógica para Luau e executando o resultado em seguida.

### 2.8. HTTP & Parser (`_G.BABFT.HTTP`, `_G.BABFT.Parser`)
Módulos utilitários para requisições web e processamento de dados.

*   **`HTTP.get(url: string)`**
    *   **Parâmetros:** `url` (Endereço web).
    *   **Retorno:** String (Corpo da resposta).
    *   **Descrição:** Faz uma requisição GET assíncrona.
*   **`Parser.parseJSON(jsonStr: string, autoBuild: boolean)`**
    *   **Parâmetros:** `jsonStr` (String JSON), `autoBuild` (Booleano).
    *   **Descrição:** Converte uma string JSON em uma tabela Lua. Se `autoBuild` for verdadeiro, tenta interpretar o JSON como um esquema de construção e instancia os blocos automaticamente.

---

## 3. Sintaxe Simplificada (DSL)

A engine expõe uma Domain Specific Language (DSL) no ambiente global para facilitar a manipulação de blocos sem a necessidade de chamar as bibliotecas completas.

Todas as coordenadas `(X, Y, Z)` passadas para a DSL são relativas ao centro da base do jogador (obtido via `Core.getCenter()`).

### 3.1. Criação de Blocos (`PorBloco`)
Cria um bloco na posição especificada. O nome da função deve corresponder ao nome do bloco.

```lua
PorBloco.WoodBlock(0, 5, 0)
PorBloco.PlasticBlock(10, 5, 10)
PorBloco.NeonBlock(-5, 10, -5)
```

### 3.2. Coloração de Blocos (`CorBloco`)
Altera a cor de um bloco. Os valores devem ser RGB (0 a 255).

```lua
CorBloco.WoodBlock(255, 0, 0)    -- Vermelho
CorBloco.PlasticBlock(0, 255, 0) -- Verde
CorBloco.NeonBlock(0, 0, 255)    -- Azul
```

### 3.3. Escalonamento (`EscalaBloco`)
Modifica o tamanho do bloco nos eixos X, Y e Z.

```lua
EscalaBloco.WoodBlock(5, 5, 5)
EscalaBloco.PlasticBlock(1, 10, 1)
```

### 3.4. Rotação (`RotacaoBloco`)
Gira o bloco em graus nos eixos X, Y e Z.

```lua
RotacaoBloco.WoodBlock(0, 90, 0)
RotacaoBloco.PlasticBlock(45, 0, 45)
```

### 3.5. Movimentação (`MoverPara`)
Move o bloco para uma nova coordenada (X, Y, Z) relativa ao centro da base.

```lua
MoverPara.WoodBlock(0, 20, 0)
MoverPara.PlasticBlock(50, 5, 50)
```

### 3.6. Deleção (`DeletarBloco`)
Remove o bloco especificado do mundo.

```lua
DeletarBloco.WoodBlock()
DeletarBloco.PlasticBlock()
```

---

## 4. Posições Relativas e Sufixos

Para construções complexas, a DSL suporta sufixos de posicionamento relativo. Isso permite criar múltiplos blocos do mesmo tipo e referenciá-los com base em sua posição em relação ao centro.

Os sufixos disponíveis são:
*   `.MinhaFrente1`, `.MinhaFrente2`, `.MinhaFrente3`...
*   `.MinhaTras1`, `.MinhaTras2`...
*   `.MinhaEsquerda1`, `.MinhaEsquerda2`...
*   `.MinhaDireita1`, `.MinhaDireita2`...
*   `.MeuCima1`, `.MeuCima2`...
*   `.MeuBaixo1`, `.MeuBaixo2`...

### 4.1. Como usar Sufixos

Quando você usa um sufixo com `PorBloco`, a engine registra aquele bloco com um identificador único. Você deve usar o mesmo sufixo nas outras funções da DSL para modificar aquele bloco específico.

**Exemplo de Construção:**

```lua
-- Cria um bloco na frente
PorBloco.MinhaFrente1(0, 0, -10)
CorBloco.MinhaFrente1(253, 253, 253)
EscalaBloco.MinhaFrente1(5, 5, 8)

-- Cria um segundo bloco na frente, mais distante
PorBloco.MinhaFrente2(0, 0, -20)
CorBloco.MinhaFrente2(255, 0, 0)
EscalaBloco.MinhaFrente2(10, 10, 10)

-- Cria um bloco à esquerda
PorBloco.MinhaEsquerda1(-15, 0, 0)
RotacaoBloco.MinhaEsquerda1(0, 45, 0)
```

### 4.2. Encadeamento Lógico
O uso de sufixos garante que as operações de cor, escala e rotação sejam aplicadas exatamente à instância correta, mesmo que existam dezenas de blocos do mesmo material no mapa. O número no final do sufixo (1, 2, 3) serve apenas como um identificador sequencial para diferenciar os blocos na mesma direção.

---

## 5. Considerações de Uso

*   **Limites de Execução:** Ao usar a função `Polyglot.execute` ou `AI.execute`, lembre-se que o código gerado é executado no contexto do cliente.
*   **Gerenciamento de Memória:** O histórico da IA é limitado a 10 mensagens para evitar consumo excessivo de memória e manter as requisições HTTP dentro de tamanhos aceitáveis.
*   **Referências de CFrame:** Sempre assuma que `(0, 0, 0)` na DSL não é o centro do mapa global, mas sim o centro exato da base (plot) designada ao seu personagem.
