# 🔐 AES-128 em FPGA — Implementação Iterativa

> Repositório destinado ao desenvolvimento da Iniciação Científica sobre criptografia **AES-128** implementada em FPGA, utilizando uma arquitetura **iterativa** com máquinas de estados finitos (FSMs).

---

## 📑 Sumário

- [Visão Geral do AES-128](#-visão-geral-do-aes-128)
- [Por que AES-128?](#-por-que-aes-128)
- [Conceitos Matemáticos Fundamentais](#-conceitos-matemáticos-fundamentais)
  - [O Campo de Galois GF(2⁸)](#o-campo-de-galois-gf2⁸)
  - [Operação XOR como soma](#operação-xor-como-soma)
  - [Multiplicação em GF(2⁸)](#multiplicação-em-gf2⁸)
- [A Matriz de Estado (State Matrix)](#-a-matriz-de-estado-state-matrix)
- [Fluxo Geral da Cifra AES-128](#-fluxo-geral-da-cifra-aes-128)
- [Detalhamento das Operações](#-detalhamento-das-operações)
  - [SubBytes (Substituição de Bytes)](#1-subbytes-substituição-de-bytes)
  - [ShiftRows (Deslocamento de Linhas)](#2-shiftrows-deslocamento-de-linhas)
  - [MixColumns (Mistura de Colunas)](#3-mixcolumns-mistura-de-colunas)
  - [AddRoundKey (Adição de Chave da Rodada)](#4-addroundkey-adição-de-chave-da-rodada)
- [Key Schedule (Expansão de Chave)](#-key-schedule-expansão-de-chave)
- [Arquitetura do Projeto em FPGA](#-arquitetura-do-projeto-em-fpga)
- [Detalhamento dos Componentes HDL](#-detalhamento-dos-componentes-hdl)
  - [aes_package.vhd](#aes_packagevhd--pacote-de-tipos-e-funções)
  - [sbox.vhd](#sboxvhd--tabela-de-substituição)
  - [SubBytes_ShiftRows.vhd](#subbytes_shiftrowsvhd--substituição--deslocamento)
  - [MixColumns.vhd](#mixcolumnsvhd--mistura-de-colunas)
  - [AddRoundKey.vhd](#addroundkeyvhd--adição-de-chave)
  - [KeySchedule.vhd](#keyschedulevhd--expansão-de-uma-rodada-de-chave)
  - [KeySchedules_FSM.vhd](#keyschedules_fsmvhd--orquestrador-da-expansão-de-chave)
  - [Encrypt_FSM.vhd](#encrypt_fsmvhd--fsm-principal-de-encriptação)
  - [aes_iterativo.vhd](#aes_iterativovhd--entidade-top-level)
- [Testbenches](#-testbenches)
- [Vetor de Teste NIST (FIPS-197)](#-vetor-de-teste-nist-fips-197)
- [Estrutura de Diretórios](#-estrutura-de-diretórios)
- [Licença](#-licença)

---

## 🌍 Visão Geral do AES-128

O **AES** (*Advanced Encryption Standard*) é o padrão mundial de criptografia simétrica, adotado pelo governo dos EUA (NIST) em 2001 para substituir o DES. O "128" refere-se ao tamanho da chave: **128 bits** (16 bytes).

**Criptografia simétrica** significa que a **mesma chave** usada para cifrar é usada para decifrar. Imagine um cadeado onde tanto quem tranca quanto quem destranca usa a mesma chave física.

O AES-128 opera sobre **blocos de 128 bits** (16 bytes) por vez. Se a mensagem for maior, ela é dividida em blocos de 16 bytes e cada bloco é cifrado independentemente (no modo ECB).

### Parâmetros do AES-128

| Parâmetro             | Valor    |
|-----------------------|----------|
| Tamanho do bloco      | 128 bits |
| Tamanho da chave      | 128 bits |
| Número de rodadas     | 10       |
| Tamanho da palavra    | 32 bits  |

---

## 🎯 Por que AES-128?

- **Padrão mundial**: Usado em TLS/SSL (HTTPS), Wi-Fi (WPA2/WPA3), discos criptografados, VPNs, etc.
- **Segurança comprovada**: Não existe ataque prático conhecido contra o AES-128 completo.
- **Eficiência em hardware**: As operações do AES foram projetadas pensando em implementação eficiente em circuitos digitais.
- **Paralelismo natural**: Muitas operações podem ser executadas simultaneamente, ideal para FPGAs.

---

## 🧮 Conceitos Matemáticos Fundamentais

Antes de entender cada etapa do AES, é essencial compreender três conceitos matemáticos. Não se assuste — vou explicar cada um de forma intuitiva.

### O Campo de Galois GF(2⁸)

O AES trabalha com **bytes** (8 bits). Cada byte é tratado como um elemento de um "universo matemático" especial chamado **GF(2⁸)** — leia-se "Campo de Galois com 2 elevado a 8 elementos", ou seja, um universo com **256 elementos** (de `0x00` a `0xFF`).

**Por que esse campo existe?** Porque precisamos de operações matemáticas (soma, multiplicação, inverso) que:
1. Sempre resultem em outro byte (nunca "estouram" para mais de 8 bits)
2. Todo elemento (exceto zero) tenha um inverso multiplicativo

Pense assim: em aritmética normal, `200 + 200 = 400`, que não cabe em um byte. No GF(2⁸), as regras são diferentes para garantir que o resultado **sempre** cabe em 8 bits.

#### Representação polinomial

Cada byte pode ser lido como um polinômio. Por exemplo, o byte `0x57` = `01010111` em binário:

```
0·x⁷ + 1·x⁶ + 0·x⁵ + 1·x⁴ + 0·x³ + 1·x² + 1·x¹ + 1·x⁰
= x⁶ + x⁴ + x² + x + 1
```

Essa representação é puramente conceitual para definir as regras matemáticas — no hardware, continuamos trabalhando com bits normais.

---

### Operação XOR como soma

No GF(2⁸), a **soma** de dois bytes é simplesmente o **XOR bit a bit**:

```
Soma em GF(2⁸):   a ⊕ b   (XOR)

Exemplo:
  0x57 ⊕ 0x83
  = 01010111
  ⊕ 10000011
  = 11010100
  = 0xD4
```

**Propriedades importantes**:
- `a ⊕ a = 0` (qualquer valor XOR ele mesmo dá zero)
- `a ⊕ 0 = a` (XOR com zero não muda nada)
- A soma e a subtração são **idênticas** (ambas são XOR)

No hardware, isso é **gratuito**: uma porta XOR é o circuito digital mais simples que existe.

---

### Multiplicação em GF(2⁸)

A multiplicação é mais complexa. Ela é feita "como se fosse" uma multiplicação de polinômios, mas com uma regra extra: se o resultado ultrapassar 8 bits (grau ≥ 8), aplicamos uma **redução modular** usando o **polinômio irredutível** do AES:

```
m(x) = x⁸ + x⁴ + x³ + x + 1    →    em hexadecimal: 0x11B
```

Esse polinômio funciona como o "módulo" na aritmética modular que conhecemos (tipo o relógio: `13 mod 12 = 1`). Ele garante que qualquer resultado de multiplicação é reduzido de volta para 8 bits.

#### Algoritmo "Russian Peasant Multiplication" (usado neste projeto)

O algoritmo implementado na função `gmul` funciona assim, passo a passo:

```
Entrada: dois bytes 'a' e 'b'
Saída:   p = a × b  em GF(2⁸)

p = 0x00

Para cada bit de 'b' (do menos significativo ao mais significativo):
    1. Se o bit atual de 'b' é 1:
         p = p ⊕ a        (acumula 'a' no resultado)
    
    2. Salva o bit mais alto de 'a' (bit 7)
    
    3. a = a << 1          (desloca 'a' para a esquerda, equivale a multiplicar por x)
    
    4. Se o bit salvo era 1:
         a = a ⊕ 0x1B     (redução modular: subtrai o polinômio m(x))
    
    5. b = b >> 1          (avança para o próximo bit de 'b')
```

**Analogia**: É parecido com a multiplicação manual que aprendemos na escola, mas usando XOR no lugar da soma e aplicando a "correção" (`⊕ 0x1B`) toda vez que o número ficaria grande demais.

**Exemplo: `0x02 × 0x57`** (multiplicar por 2 = shift left):
```
a = 0x57 = 01010111
Shift left: 10101110 = 0xAE
Bit 7 do original era 0, então NÃO faz XOR com 0x1B
Resultado: 0xAE
```

**Exemplo: `0x02 × 0xAE`** (bit 7 é 1):
```
a = 0xAE = 10101110
Shift left: 01011100 (descartando o bit 8)
Bit 7 do original era 1, então:
01011100 ⊕ 00011011 = 01000111 = 0x47
Resultado: 0x47
```

---

## 📊 A Matriz de Estado (State Matrix)

O AES organiza os 16 bytes do bloco de entrada em uma **matriz 4×4**, chamada **State** (Estado). A organização é **por colunas** (column-major):

```
Bloco de entrada (16 bytes):
b₀  b₁  b₂  b₃  b₄  b₅  b₆  b₇  b₈  b₉  b₁₀ b₁₁ b₁₂ b₁₃ b₁₄ b₁₅

Organizado na matriz State:
         Col 0   Col 1   Col 2   Col 3
Linha 0 │ b₀   │ b₄   │ b₈   │ b₁₂  │
Linha 1 │ b₁   │ b₅   │ b₉   │ b₁₃  │
Linha 2 │ b₂   │ b₆   │ b₁₀  │ b₁₄  │
Linha 3 │ b₃   │ b₇   │ b₁₁  │ b₁₅  │
```

**Exemplo concreto** com o vetor de teste NIST:
```
Plaintext: 32 43 F6 A8 88 5A 30 8D 31 31 98 A2 E0 37 07 34

State:
         Col 0   Col 1   Col 2   Col 3
Linha 0 │  32  │  88  │  31  │  E0  │
Linha 1 │  43  │  5A  │  31  │  37  │
Linha 2 │  F6  │  30  │  98  │  07  │
Linha 3 │  A8  │  8D  │  A2  │  34  │
```

Todas as operações do AES são aplicadas sobre esta matriz.

---

## 🔄 Fluxo Geral da Cifra AES-128

```
Plaintext (128 bits) ──────────┐
                               ▼
Key (128 bits) ──► Key Schedule (gera 11 subchaves: K₀ a K₁₀)
                               │
                               ▼
                    ┌──────────────────────┐
                    │  AddRoundKey (com K₀) │  ◄── Rodada Inicial
                    └──────────┬───────────┘
                               │
               ┌───────────────┴───────────────┐
               │     RODADAS 1 a 9 (repete):   │
               │                               │
               │  1. SubBytes                  │
               │  2. ShiftRows                 │
               │  3. MixColumns                │
               │  4. AddRoundKey (com Kᵢ)      │
               │                               │
               └───────────────┬───────────────┘
                               │
                    ┌──────────┴───────────┐
                    │   RODADA FINAL (10):  │
                    │                       │
                    │  1. SubBytes          │
                    │  2. ShiftRows         │
                    │  3. AddRoundKey (K₁₀) │  ◄── SEM MixColumns!
                    └──────────┬────────────┘
                               │
                               ▼
                    Ciphertext (128 bits)
```

> **Nota**: A rodada final **não** executa MixColumns. Isso não é um erro — é parte da especificação do AES e tem motivações matemáticas relacionadas à estrutura de decifragem.

---

## 🔬 Detalhamento das Operações

### 1. SubBytes (Substituição de Bytes)

**O que faz**: Substitui cada byte da matriz State por outro byte, usando uma tabela de 256 entradas chamada **S-Box** (*Substitution Box*).

**Por que existe**: Adiciona **confusão** à cifra — ou seja, torna a relação entre a chave e o texto cifrado o mais complexa possível. Sem o SubBytes, o AES seria um sistema linear (fácil de quebrar com álgebra).

**Como funciona matematicamente** (em duas etapas):

**Etapa 1** — Inversão multiplicativa em GF(2⁸):
```
b' = b⁻¹  em GF(2⁸)     (sendo que 0⁻¹ = 0 por definição)
```
Isso significa: para cada byte `b`, encontramos o byte `b'` tal que `b × b' = 1` no campo de Galois. Por exemplo, `0x53⁻¹ = 0xCA` porque `0x53 × 0xCA = 0x01` em GF(2⁸).

**Etapa 2** — Transformação afim (operação com bits):
```
Para cada bit i (0 a 7) do resultado b':

s(i) = b'(i) ⊕ b'((i+4) mod 8) ⊕ b'((i+5) mod 8) ⊕ b'((i+6) mod 8) ⊕ b'((i+7) mod 8) ⊕ c(i)

Onde c = 0x63 = 01100011
```

Na prática, essa combinação de inversão + transformação afim já foi **pré-calculada** para todos os 256 valores possíveis e armazenada na tabela S-Box:

```
S-Box (16×16, indexada pelo nibble alto = linha, nibble baixo = coluna):

     │  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
─────┼────────────────────────────────────────────────────────────────────
  0  │ 63  7C  77  7B  F2  6B  6F  C5  30  01  67  2B  FE  D7  AB  76
  1  │ CA  82  C9  7D  FA  59  47  F0  AD  D4  A2  AF  9C  A4  72  C0
  2  │ B7  FD  93  26  36  3F  F7  CC  34  A5  E5  F1  71  D8  31  15
  3  │ 04  C7  23  C3  18  96  05  9A  07  12  80  E2  EB  27  B2  75
  4  │ 09  83  2C  1A  1B  6E  5A  A0  52  3B  D6  B3  29  E3  2F  84
  5  │ 53  D1  00  ED  20  FC  B1  5B  6A  CB  BE  39  4A  4C  58  CF
  6  │ D0  EF  AA  FB  43  4D  33  85  45  F9  02  7F  50  3C  9F  A8
  7  │ 51  A3  40  8F  92  9D  38  F5  BC  B6  DA  21  10  FF  F3  D2
  8  │ CD  0C  13  EC  5F  97  44  17  C4  A7  7E  3D  64  5D  19  73
  9  │ 60  81  4F  DC  22  2A  90  88  46  EE  B8  14  DE  5E  0B  DB
  A  │ E0  32  3A  0A  49  06  24  5C  C2  D3  AC  62  91  95  E4  79
  B  │ E7  C8  37  6D  8D  D5  4E  A9  6C  56  F4  EA  65  7A  AE  08
  C  │ BA  78  25  2E  1C  A6  B4  C6  E8  DD  74  1F  4B  BD  8B  8A
  D  │ 70  3E  B5  66  48  03  F6  0E  61  35  57  B9  86  C1  1D  9E
  E  │ E1  F8  98  11  69  D9  8E  94  9B  1E  87  E9  CE  55  28  DF
  F  │ 8C  A1  89  0D  BF  E6  42  68  41  99  2D  0F  B0  54  BB  16
```

**Exemplo**: `SubBytes(0x53) = 0xED`
- Nibble alto: `5` → linha 5
- Nibble baixo: `3` → coluna 3
- Intersecção = `ED`

**No hardware**: A S-Box é implementada como uma **lookup table (LUT)** — um array de 256 posições. O byte de entrada vira o endereço, e o byte de saída é o dado armazenado naquele endereço. É **puramente combinacional** (sem clock): o resultado aparece instantaneamente.

---

### 2. ShiftRows (Deslocamento de Linhas)

**O que faz**: Desloca circularmente cada linha da matriz State para a **esquerda**, com deslocamentos diferentes para cada linha.

**Por que existe**: Adiciona **difusão** entre as colunas. Sem o ShiftRows, cada coluna da matriz seria processada independentemente, e o atacante poderia quebrar a cifra coluna por coluna.

**Regra**:
```
Linha 0: sem deslocamento        (shift = 0)
Linha 1: desloca 1 posição       (shift = 1)
Linha 2: desloca 2 posições      (shift = 2)
Linha 3: desloca 3 posições      (shift = 3)
```

**Fórmula**:
```
State'(r, c) = State(r, (c + r) mod 4)

Onde:
  r = linha (0 a 3)
  c = coluna (0 a 3)
```

**Exemplo visual**:
```
ANTES:                          DEPOIS:
│ a₀ │ a₁ │ a₂ │ a₃ │         │ a₀ │ a₁ │ a₂ │ a₃ │  ← sem mudança
│ b₀ │ b₁ │ b₂ │ b₃ │    →    │ b₁ │ b₂ │ b₃ │ b₀ │  ← shift 1
│ c₀ │ c₁ │ c₂ │ c₃ │    →    │ c₂ │ c₃ │ c₀ │ c₁ │  ← shift 2
│ d₀ │ d₁ │ d₂ │ d₃ │    →    │ d₃ │ d₀ │ d₁ │ d₂ │  ← shift 3
```

**No hardware**: É implementado como **roteamento de fios** — literalmente reconectar entradas e saídas. Neste projeto, o ShiftRows é integrado ao SubBytes: o deslocamento é feito **antes** da substituição, usando a indexação `(c + r) mod 4` na entrada das S-Boxes.

---

### 3. MixColumns (Mistura de Colunas)

**O que faz**: Transforma cada coluna da matriz State multiplicando-a por uma **matriz fixa** no campo GF(2⁸).

**Por que existe**: Adiciona **difusão** dentro de cada coluna — faz com que cada byte de saída dependa de **todos os 4 bytes** da coluna de entrada. Combinado com o ShiftRows (que mistura entre colunas), isso garante que, após algumas rodadas, cada byte do texto cifrado depende de **todos** os bytes do texto original.

**Fórmula matricial** (para cada coluna):

```
┌     ┐     ┌             ┐   ┌     ┐
│ s'₀ │     │ 02  03  01  01 │   │ s₀  │
│ s'₁ │  =  │ 01  02  03  01 │ × │ s₁  │    (multiplicação em GF(2⁸))
│ s'₂ │     │ 01  01  02  03 │   │ s₂  │
│ s'₃ │     │ 03  01  01  02 │   │ s₃  │
└     ┘     └             ┘   └     ┘
```

**Expandindo para cada byte do resultado**:
```
s'₀ = (02 • s₀) ⊕ (03 • s₁) ⊕ (01 • s₂) ⊕ (01 • s₃)
s'₁ = (01 • s₀) ⊕ (02 • s₁) ⊕ (03 • s₂) ⊕ (01 • s₃)
s'₂ = (01 • s₀) ⊕ (01 • s₁) ⊕ (02 • s₂) ⊕ (03 • s₃)
s'₃ = (03 • s₀) ⊕ (01 • s₁) ⊕ (01 • s₂) ⊕ (02 • s₃)
```

Onde:
- `•` é multiplicação em GF(2⁸) (função `gmul`)
- `⊕` é XOR
- `01 • x = x` (multiplicar por 1 não muda nada)
- `02 • x` = shift left + redução condicional (ver seção de multiplicação GF(2⁸))
- `03 • x = (02 • x) ⊕ x` (porque 3 = 2 + 1, e a soma é XOR)

**No hardware**: Cada coluna é processada pela função `mix_single_column`, que aplica as 4 fórmulas acima. As 4 colunas são processadas **em paralelo** dentro de um único ciclo de clock.

---

### 4. AddRoundKey (Adição de Chave da Rodada)

**O que faz**: Aplica XOR entre a matriz State e a subchave da rodada atual.

**Por que existe**: É a **única operação que usa a chave secreta**. Sem ela, a cifra seria uma função fixa — qualquer pessoa que conhecesse o algoritmo poderia cifrar/decifrar sem precisar da chave. O AddRoundKey é o que torna a cifra **dependente da chave**.

**Fórmula**:
```
State'(r, c) = State(r, c) ⊕ RoundKey(r, c)

Para todo r ∈ {0,1,2,3} e c ∈ {0,1,2,3}
```

Ou de forma matricial:
```
State' = State ⊕ Kᵢ     (XOR byte a byte entre as duas matrizes 4×4)
```

**Exemplo**:
```
State:              RoundKey (K₀):        Resultado:
│ 32 88 31 E0 │     │ 2B 28 AB 09 │       │ 19 A0 9A E9 │
│ 43 5A 31 37 │  ⊕  │ 7E AE F7 CF │   =   │ 3D F4 C6 F8 │
│ F6 30 98 07 │     │ 15 D2 15 4F │       │ E3 E2 8D 48 │
│ A8 8D A2 34 │     │ 16 A6 88 3C │       │ BE 2B 2A 08 │
```

**No hardware**: É a operação mais simples de todas — 128 portas XOR em paralelo, uma por bit.

---

## 🔑 Key Schedule (Expansão de Chave)

O AES-128 precisa de **11 subchaves** (K₀ a K₁₀), uma para cada AddRoundKey. Como a chave de entrada tem apenas 128 bits (= 1 subchave), precisamos **expandir** a chave original para gerar as outras 10.

### Visão geral

```
Chave Original (128 bits = 4 palavras de 32 bits)
    │
    ├──► K₀ = Chave Original
    │
    ├──► K₁ = f(K₀, RCON[1])
    ├──► K₂ = f(K₁, RCON[2])
    ├──► K₃ = f(K₂, RCON[3])
    │      ...
    └──► K₁₀ = f(K₉, RCON[10])
```

### Geração de uma subchave Kᵢ a partir de Kᵢ₋₁

Cada subchave é uma matriz 4×4 (4 colunas de 4 bytes). Chamamos as colunas de `W₀, W₁, W₂, W₃`.

Para gerar a nova subchave a partir da anterior:

#### Coluna 0 (a mais complexa):

```
                    ┌──────────────┐
W₃ da chave anterior──►│   RotWord    │  Rotação circular para cima
                    └──────┬───────┘
                           ▼
                    ┌──────────────┐
                    │   SubWord    │  Aplica S-Box em cada byte
                    └──────┬───────┘
                           ▼
Nova_W₀ = SubWord(RotWord(W₃_anterior)) ⊕ W₀_anterior ⊕ RCON[i]
```

Onde:

**RotWord** — Rotação circular de 1 posição para cima:
```
RotWord([a, b, c, d]) = [b, c, d, a]
```

**SubWord** — Aplica a S-Box em cada byte da palavra:
```
SubWord([a, b, c, d]) = [S-Box(a), S-Box(b), S-Box(c), S-Box(d)]
```

**RCON** — Constante de rodada (Round Constant):
```
RCON[i] = [rc(i), 0x00, 0x00, 0x00]

Onde rc(i) é:
  rc(1)  = 0x01
  rc(2)  = 0x02
  rc(3)  = 0x04
  rc(4)  = 0x08
  rc(5)  = 0x10
  rc(6)  = 0x20
  rc(7)  = 0x40
  rc(8)  = 0x80
  rc(9)  = 0x1B   (0x80 << 1 = 0x100, reduzido por ⊕ 0x11B = 0x1B)
  rc(10) = 0x36   (0x1B << 1 = 0x36)
```

Note que `rc(i) = 2 × rc(i-1)` em GF(2⁸) — é multiplicação por `x` no campo de Galois!

#### Colunas 1, 2 e 3 (simples):
```
Nova_W₁ = Nova_W₀ ⊕ W₁_anterior
Nova_W₂ = Nova_W₁ ⊕ W₂_anterior
Nova_W₃ = Nova_W₂ ⊕ W₃_anterior
```

Cada coluna é simplesmente o XOR da coluna recém-calculada com a coluna correspondente da chave anterior. É uma cascata de XORs.

### Exemplo com a chave NIST

```
Chave original: 2B 7E 15 16 28 AE D2 A6 AB F7 15 88 09 CF 4F 3C

W₀ = [2B, 7E, 15, 16]
W₁ = [28, AE, D2, A6]
W₂ = [AB, F7, 15, 88]
W₃ = [09, CF, 4F, 3C]

Gerando K₁:
  RotWord(W₃)     = [CF, 4F, 3C, 09]
  SubWord(...)     = [8A, 84, EB, 01]
  ⊕ RCON[1]       = [8A⊕01, 84⊕00, EB⊕00, 01⊕00] = [8B, 84, EB, 01]
  Nova_W₀ = [8B, 84, EB, 01] ⊕ [2B, 7E, 15, 16] = [A0, FA, FE, 17]
  Nova_W₁ = [A0, FA, FE, 17] ⊕ [28, AE, D2, A6] = [88, 54, 2C, B1]
  Nova_W₂ = [88, 54, 2C, B1] ⊕ [AB, F7, 15, 88] = [23, A3, 39, 39]
  Nova_W₃ = [23, A3, 39, 39] ⊕ [09, CF, 4F, 3C] = [2A, 6C, 76, 05]
```

---

## 🏗️ Arquitetura do Projeto em FPGA

Este projeto implementa o AES-128 usando uma **arquitetura iterativa**: ao invés de replicar o hardware das 10 rodadas (o que gastaria muita área), um **único conjunto de hardware** é reutilizado para todas as rodadas, controlado por uma FSM.

```
┌────────────────────────────────────────────────────────────┐
│                    Encrypt_FSM (Top)                       │
│                                                            │
│  ┌──────────────────┐     ┌──────────────────────────┐     │
│  │                  │     │    SubBytes + ShiftRows   │     │
│  │  KeySchedules    │     │  ┌─────┐ ┌─────┐ ┌─────┐ │     │
│  │  _FSM            │     │  │SBox │ │SBox │ │ ... │ │     │
│  │  ┌────────────┐  │     │  └─────┘ └─────┘ └─────┘ │     │
│  │  │KeySchedule │  │     └──────────┬───────────────┘     │
│  │  │  ┌──────┐  │  │                │                     │
│  │  │  │ SBox │  │  │     ┌──────────▼───────────────┐     │
│  │  │  └──────┘  │  │     │       MixColumns          │     │
│  │  └────────────┘  │     │    (gmul + XOR logic)     │     │
│  │                  │     └──────────┬───────────────┘     │
│  │  Keychain[0..10] │                │                     │
│  └──────┬───────────┘     ┌──────────▼───────────────┐     │
│         │                 │      AddRoundKey          │     │
│         └────────────────►│     (matrix XOR)          │     │
│                           └──────────────────────────┘     │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              FSM de Controle Principal                │  │
│  │  IDLE → KS_START → KS_WAIT → INITIAL → ROUNDS →     │  │
│  │  SUBBYTES → MIXCOLUMNS → ADDROUNDKEY → ... → DONE   │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

**Vantagens da arquitetura iterativa**:
- **Menor área**: Apenas 1 instância de cada componente
- **Controlável**: Uma FSM gerencia todo o fluxo
- **Determinístico**: Número fixo de ciclos de clock por encriptação

**Desvantagem**:
- **Mais lenta**: Precisa de múltiplos ciclos de clock (uma alternativa seria pipeline/unrolled, que usa mais área mas é mais rápido)

---

## 📁 Detalhamento dos Componentes HDL

### `aes_package.vhd` — Pacote de Tipos e Funções

**Arquivo**: [`aes_package.vhd`](ImplementacaoIterativa/aes_package.vhd)

Define os tipos de dados e funções matemáticas reutilizadas por todos os componentes.

#### Tipos definidos

| Tipo                 | Descrição                                                        |
|----------------------|------------------------------------------------------------------|
| `byte`               | Vetor de 8 bits (`std_logic_vector(7 downto 0)`)                 |
| `byte_column`        | Array de 4 bytes — representa uma coluna da matriz State         |
| `matrix`             | Array 4×4 de bytes — a matriz State completa (128 bits)          |
| `matrix_128`         | Array de matrizes — usado para armazenar o keychain (11 chaves)  |
| `rcon_array`         | Array com as 11 constantes RCON (`0x00` a `0x36`)                |

#### Funções definidas

| Função                | O que faz                                                         |
|-----------------------|-------------------------------------------------------------------|
| `byte_xor(a, b)`     | XOR bit a bit entre dois bytes                                    |
| `column_xor(a, b)`   | XOR entre duas colunas (4 bytes)                                  |
| `matrix_xor(a, b)`   | XOR entre duas matrizes 4×4 (16 bytes = 128 bits)                 |
| `column2matrix()`    | Monta uma matriz a partir de 4 colunas                            |
| `matrix2column(M,c)` | Extrai a coluna `c` de uma matriz `M`                             |
| `column_rotate()`    | Rotação circular de uma coluna (usado no RotWord)                 |
| `gmul(a, b)`         | Multiplicação em GF(2⁸) — algoritmo Russian Peasant               |
| `mix_single_column()`| Aplica a transformação MixColumns em uma única coluna             |

#### Constante RCON

```
RCON = [0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36]
         ↑      ↑     ↑     ...                                    ↑
      (não    round  round                                       round
      usado)    1      2                                           10
```

---

### `sbox.vhd` — Tabela de Substituição

**Arquivo**: [`sbox.vhd`](ImplementacaoIterativa/rtl/sbox.vhd)

#### Interface

| Porta         | Direção | Tamanho | Descrição                              |
|---------------|---------|---------|----------------------------------------|
| `input_byte`  | IN      | 8 bits  | Byte a ser substituído                 |
| `output_byte` | OUT     | 8 bits  | Byte após substituição pela S-Box      |

#### Funcionamento

É um **circuito combinacional puro** (sem clock, sem FSM). Implementa a S-Box como um array constante de 256 entradas. O byte de entrada é convertido para inteiro e usado como índice para acessar a tabela.

```
output_byte = SBOX_TABLE[input_byte]
```

São instanciadas **16 cópias** da S-Box no projeto:
- 16 instâncias no componente SubBytes_ShiftRows (uma por byte da matriz)
- 4 instâncias no componente KeySchedule (uma por byte da palavra SubWord)

---

### `SubBytes_ShiftRows.vhd` — Substituição + Deslocamento

**Arquivo**: [`SubBytes_ShiftRows.vhd`](ImplementacaoIterativa/rtl/SubBytes_ShiftRows.vhd)

Este componente funde as operações **SubBytes** e **ShiftRows** em uma única etapa, aproveitando que ambas são independentes por byte.

#### Interface

| Porta      | Direção | Tipo     | Descrição                                |
|------------|---------|----------|------------------------------------------|
| `data_in`  | IN      | matrix   | Estado atual (4×4 bytes)                 |
| `data_out` | OUT     | matrix   | Estado após SubBytes + ShiftRows         |
| `start`    | IN      | 1 bit    | Pulso de início (1 ciclo de clock)       |
| `done`     | OUT     | 1 bit    | Sinaliza término da operação             |
| `clk`      | IN      | 1 bit    | Clock do sistema                         |
| `rst`      | IN      | 1 bit    | Reset síncrono (ativo alto)              |

#### Como funciona

A "mágica" está na forma como o ShiftRows e o SubBytes são fundidos:

```
Para cada posição (r, c) da matriz de saída:
    sbox_in(r, c) = data_in(r, (c + r) mod 4)     ← ShiftRows (roteamento)
    sbox_out(r, c) = S-Box(sbox_in(r, c))          ← SubBytes (substituição)
```

Ou seja, **primeiro** a entrada é re-indexada (ShiftRows), **depois** passa pela S-Box (SubBytes). Como a S-Box é combinacional, o resultado está disponível quase instantaneamente.

#### FSM interna

```
        ┌──────┐   start=1   ┌────────────┐
   ──►  │ IDLE │ ──────────► │ PROCESSING │
        │done=0│             │  done=1    │
        └──┬───┘  ◄───────── └────────────┘
           │         (auto)
           └── start=0: permanece
```

**Estados**:
- `IDLE`: Aguarda `start`. Done = 0.
- `PROCESSING`: O resultado combinacional já está pronto. Sinaliza `done = 1` e volta ao `IDLE` no próximo ciclo.

**Latência**: 2 ciclos de clock (1 para transição IDLE→PROCESSING, 1 para sinalizar done).

---

### `MixColumns.vhd` — Mistura de Colunas

**Arquivo**: [`MixColumns.vhd`](ImplementacaoIterativa/rtl/MixColumns.vhd)

#### Interface

| Porta      | Direção | Tipo     | Descrição                                |
|------------|---------|----------|------------------------------------------|
| `data_in`  | IN      | matrix   | Estado após SubBytes+ShiftRows           |
| `data_out` | OUT     | matrix   | Estado após MixColumns                   |
| `start`    | IN      | 1 bit    | Pulso de início                          |
| `done`     | OUT     | 1 bit    | Sinaliza término                         |
| `clk`      | IN      | 1 bit    | Clock do sistema                         |
| `rst`      | IN      | 1 bit    | Reset síncrono                           |

#### Como funciona

Quando `start` é pulsado:
1. Para cada coluna `c` (0 a 3):
   - Extrai a coluna usando `matrix2column(data_in, c)`
   - Aplica `mix_single_column()` (as 4 fórmulas com `gmul`)
   - Escreve o resultado em `data_out`

A função `mix_single_column` calcula:
```
res(0) = gmul(0x02, col(0)) ⊕ gmul(0x03, col(1)) ⊕ col(2)           ⊕ col(3)
res(1) = col(0)              ⊕ gmul(0x02, col(1)) ⊕ gmul(0x03, col(2)) ⊕ col(3)
res(2) = col(0)              ⊕ col(1)              ⊕ gmul(0x02, col(2)) ⊕ gmul(0x03, col(3))
res(3) = gmul(0x03, col(0)) ⊕ col(1)              ⊕ col(2)              ⊕ gmul(0x02, col(3))
```

#### FSM interna

```
        ┌──────┐   start=1   ┌────────────┐
   ──►  │ IDLE │ ──────────► │ PROCESSING │
        │done=0│   (calcula)  │  done=1    │
        └──┬───┘  ◄───────── └────────────┘
           │         (auto)
           └── start=0: permanece
```

**Latência**: 2 ciclos de clock.

**Nota**: No estado `IDLE`, quando `start=1`, o cálculo das 4 colunas é feito usando variáveis (que são imediatas em VHDL) e o resultado é registrado em sinais no mesmo ciclo. O estado `PROCESSING` apenas sinaliza `done=1`.

---

### `AddRoundKey.vhd` — Adição de Chave

**Arquivo**: [`AddRoundKey.vhd`](ImplementacaoIterativa/rtl/AddRoundKey.vhd)

#### Interface

| Porta      | Direção | Tipo     | Descrição                                |
|------------|---------|----------|------------------------------------------|
| `data_in`  | IN      | matrix   | Estado atual                             |
| `key_in`   | IN      | matrix   | Subchave da rodada atual                 |
| `data_out` | OUT     | matrix   | Estado após XOR com a chave              |
| `clk`      | IN      | 1 bit    | Clock do sistema                         |
| `rst`      | IN      | 1 bit    | Reset síncrono                           |

#### Como funciona

A cada borda de subida do clock:
```
data_out = data_in XOR key_in     (128 bits em paralelo)
```

**Nota**: Este componente **não possui FSM nem sinal start/done**. O XOR é aplicado a cada ciclo de clock quando `rst = '0'`. A FSM principal (`Encrypt_FSM`) controla quando os dados corretos estão nas entradas e quando o resultado deve ser capturado.

**Latência**: 1 ciclo de clock (registrado).

**Nota de implementação**: Nesta versão do projeto, o AddRoundKey é feito diretamente pela `Encrypt_FSM` usando a função `matrix_xor` do pacote, sem instanciar o componente `AddRoundKey` separadamente. O componente existe como módulo reutilizável.

---

### `KeySchedule.vhd` — Expansão de Uma Rodada de Chave

**Arquivo**: [`KeySchedule.vhd`](ImplementacaoIterativa/rtl/KeySchedule.vhd)

Gera uma **única** subchave a partir da anterior.

#### Interface

| Porta      | Direção | Tipo     | Descrição                                |
|------------|---------|----------|------------------------------------------|
| `key_in`   | IN      | matrix   | Subchave da rodada anterior              |
| `key_out`  | OUT     | matrix   | Nova subchave gerada                     |
| `Rcon`     | IN      | 8 bits   | Constante de rodada (RCON[i])            |
| `en`       | IN      | 1 bit    | Enable — habilita o processamento        |
| `start`    | IN      | 1 bit    | Pulso de início                          |
| `done`     | OUT     | 1 bit    | Sinaliza término                         |
| `clk`      | IN      | 1 bit    | Clock do sistema                         |
| `rst`      | IN      | 1 bit    | Reset síncrono                           |

#### Circuitos combinacionais (sempre ativos)

Duas operações são feitas **fora** do processo (combinacionalmente):

1. **RotWord**: Extrai a coluna 3 da chave e rotaciona 1 posição:
   ```
   rotated_column3 = column_rotate(matrix2column(key_in, 3), 1)
   ```
   ```
   [a, b, c, d] → [b, c, d, a]
   ```

2. **SubWord**: Aplica 4 instâncias da S-Box nos 4 bytes da coluna rotacionada:
   ```
   sbox_out[i] = S-Box(rotated_column3[i])    para i = 0, 1, 2, 3
   ```

#### FSM interna

```
┌──────┐  start=1  ┌──────┐          ┌──────┐          ┌──────┐          ┌──────┐
│ IDLE │ ────────► │ COL0 │ ───────► │ COL1 │ ───────► │ COL2 │ ───────► │ COL3 │
│      │  (latch   │      │  (calc    │      │  (calc    │      │  (calc    │done=1│
│      │  key_in)  │      │  W₀)      │      │  W₁)      │      │  W₂)      │      │
└──────┘           └──────┘          └──────┘          └──────┘          └──┬───┘
    ▲                                                                       │
    └───────────────────────────────────────────────────────────────────────┘
```

**Processamento por estado**:

| Estado | Operação                                                                                   |
|--------|--------------------------------------------------------------------------------------------|
| IDLE   | Aguarda `start`. Quando recebe, armazena `key_in` internamente (latch).                     |
| COL0   | `new_W₀[i] = sbox_out[i] ⊕ W₀_anterior[i]` e `new_W₀[0] = ... ⊕ Rcon` (XOR extra no byte 0) |
| COL1   | `new_W₁ = new_W₀ ⊕ W₁_anterior`                                                           |
| COL2   | `new_W₂ = new_W₁ ⊕ W₂_anterior`                                                           |
| COL3   | `new_W₃ = new_W₂ ⊕ W₃_anterior` → monta `key_out` → `done = 1`                            |

**Latência**: 5 ciclos de clock (IDLE + COL0 + COL1 + COL2 + COL3).

---

### `KeySchedules_FSM.vhd` — Orquestrador da Expansão de Chave

**Arquivo**: [`KeySchedules_FSM.vhd`](ImplementacaoIterativa/rtl/KeySchedules_FSM.vhd)

Orquestra a geração de **todas as 10 subchaves**, armazenando-as em um array (`keychain`).

#### Interface

| Porta           | Direção | Tipo               | Descrição                                 |
|-----------------|---------|--------------------|-------------------------------------------|
| `key_in`        | IN      | matrix             | Chave original (128 bits)                 |
| `keychain_out`  | OUT     | matrix_128(10..0)  | Array com as 11 subchaves (K₀ a K₁₀)     |
| `start`         | IN      | 1 bit              | Pulso de início                           |
| `done`          | OUT     | 1 bit              | Sinaliza que todas as 10 chaves estão prontas |
| `clk`           | IN      | 1 bit              | Clock do sistema                          |
| `rst`           | IN      | 1 bit              | Reset síncrono                            |

#### Sinais internos

| Sinal            | Descrição                                                |
|------------------|----------------------------------------------------------|
| `round_counter`  | Contador de rodada (1 a 10)                              |
| `round_key_in`   | Chave de entrada para o módulo `KeySchedule`             |
| `round_key_out`  | Chave de saída do módulo `KeySchedule`                   |
| `Rcon_round`     | `RCON[round_counter]` — selecionado automaticamente      |

#### FSM interna

```
                         ┌───────────────┐
                         │     IDLE      │
                         │   done = 0    │
                         └───────┬───────┘
                           start=1│
                    ┌─────────────▼──────────────┐
                    │  Salva K₀ = key_in         │
                    │  round_key_in = key_in     │
                    │  round_counter = 1         │
                    └─────────────┬──────────────┘
                                  │
                         ┌────────▼────────┐
              ┌────────► │   START_KS      │
              │          │  ks_start = 1   │
              │          └────────┬────────┘
              │                   │
              │          ┌────────▼────────┐
              │          │   WAIT_KS       │
              │          │ (espera ks_done)│
              │          └────────┬────────┘
              │                   │ ks_done=1
              │          ┌────────▼────────┐
              │  cnt<10  │  Salva resultado│
              ├──────────│  no keychain[i] │
              │          │  cnt++          │
              │          └────────┬────────┘
              │                   │ cnt=10
              │          ┌────────▼────────┐
              │          │     DONE        │
              │          │   done = 1      │
              │          └─────────────────┘
              │                   │
              │                   ▼
              └───────── (volta ao IDLE)
```

**Fluxo detalhado**:
1. **IDLE**: Recebe `start`. Salva `K₀ = key_in` em `keychain_out(0)`.
2. **START_KS**: Pulsa `ks_start` para o módulo `KeySchedule`.
3. **WAIT_KS**: Espera `ks_done`. Quando pronto:
   - Salva `round_key_out` em `keychain_out(round_counter)`
   - Se `round_counter < 10`: incrementa, alimenta a saída como nova entrada, volta a START_KS
   - Se `round_counter = 10`: sinaliza `done`, volta ao IDLE

**Latência total**: Aproximadamente `10 × 6 + overhead ≈ 65-70 ciclos de clock` para gerar todas as subchaves.

---

### `Encrypt_FSM.vhd` — FSM Principal de Encriptação

**Arquivo**: [`Encrypt_FSM.vhd`](ImplementacaoIterativa/rtl/Encrypt_FSM.vhd)

O **maestro** do projeto. Coordena todos os componentes para executar a cifra AES-128 completa.

#### Interface

| Porta             | Direção | Tipo     | Descrição                                |
|-------------------|---------|----------|------------------------------------------|
| `key_in`          | IN      | matrix   | Chave original (128 bits)                |
| `data_block_in`   | IN      | matrix   | Texto claro (128 bits)                   |
| `data_block_out`  | OUT     | matrix   | Texto cifrado (128 bits)                 |
| `key_load`        | IN      | 1 bit    | Pulso para carregar/expandir a chave     |
| `start`           | IN      | 1 bit    | Pulso para iniciar a encriptação         |
| `done`            | OUT     | 1 bit    | Encriptação concluída                    |
| `busy`            | OUT     | 1 bit    | Indica que a FSM está ocupada            |
| `clk`             | IN      | 1 bit    | Clock do sistema                         |
| `rst`             | IN      | 1 bit    | Reset síncrono                           |

#### Componentes instanciados

| Instância                    | Componente             | Função                              |
|-----------------------------|------------------------|-------------------------------------|
| `Inst_KeySchedules_FSM`     | `KeySchedules_FSM`     | Expande a chave em 11 subchaves     |
| `Inst_SubBytes_ShiftRows`   | `SubBytes_ShiftRows`   | SubBytes + ShiftRows                |
| `Inst_MixColumns`           | `MixColumns`           | MixColumns                          |

> O AddRoundKey é feito diretamente via `matrix_xor()` dentro da FSM.

#### FSM — Estados e Transições

```
┌────────┐                                          
│  IDLE  │ key_load=1 → latch key → KEY_SCHEDULE_START
│        │ start=1   → latch data → INITIAL_ROUND    
└────────┘                                          
     │
     ├── KEY_SCHEDULE_START: Pulsa ks_start
     │        │
     │        ▼
     ├── KEY_SCHEDULE_WAIT: Espera ks_done → IDLE
     │
     ├── INITIAL_ROUND: State = plaintext ⊕ K₀
     │        │                  round_counter = 1
     │        ▼
     ├──► SUBBYTES_START: Alimenta SubBytes, pulsa ss_start
     │        │
     │        ▼
     │   SUBBYTES_WAIT: Espera ss_done
     │        │
     │        ├── round = 10? ──► FINAL_ROUND
     │        │
     │        ▼
     │   MIXCOLUMNS_START: Alimenta MixColumns, pulsa mc_start
     │        │
     │        ▼
     │   MIXCOLUMNS_WAIT: Espera mc_done
     │        │
     │        ▼
     │   ADD_ROUND_KEY: State = mc_out ⊕ Kᵢ
     │        │              round_counter++
     │        │
     │        └────────────── volta para SUBBYTES_START
     │
     ├── FINAL_ROUND: State = ss_out ⊕ K₁₀  (sem MixColumns!)
     │        │
     │        ▼
     ├── ENC_OUTPUT: done=1, busy=0, data_block_out = resultado
     │        │
     │        ▼
     └── ENC_DONE: done=1 → IDLE
```

#### Fluxo de operação (protocolo de uso)

**Fase 1 — Carregar e expandir a chave** (feito uma vez):
```
1. Colocar a chave em key_in
2. Pulsar key_load por 1 ciclo
3. Esperar busy voltar a '0' (key schedule concluído)
```

**Fase 2 — Cifrar um bloco** (repetível com a mesma chave):
```
1. Colocar o plaintext em data_block_in
2. Pulsar start por 1 ciclo
3. Esperar done = '1'
4. Ler o resultado em data_block_out
```

**Ciclos de clock por encriptação** (estimativa):
```
Key Schedule:     ~65-70 ciclos (feito uma vez)
Rodada Inicial:   ~2 ciclos
Rodadas 1-9:      9 × (~7 ciclos) = ~63 ciclos
Rodada Final:     ~4 ciclos
Overhead:         ~5 ciclos
Total por bloco:  ~75 ciclos (após key schedule pronto)
```

---

### `aes_iterativo.vhd` — Entidade Top-Level

**Arquivo**: [`aes_iterativo.vhd`](ImplementacaoIterativa/aes_iterativo.vhd)

Entidade de nível mais alto do projeto, definindo a interface externa com a FPGA.

#### Interface

| Porta        | Direção | Tamanho   | Descrição                   |
|--------------|---------|-----------|-----------------------------|
| `clk`        | IN      | 1 bit     | Clock do sistema            |
| `reset`      | IN      | 1 bit     | Reset do sistema            |
| `start`      | IN      | 1 bit     | Pulso de início             |
| `plaintext`  | IN      | 128 bits  | Texto claro                 |
| `key`        | IN      | 128 bits  | Chave de encriptação        |
| `ciphertext` | OUT     | 128 bits  | Texto cifrado               |
| `done`       | OUT     | 1 bit     | Encriptação concluída       |

> **Nota**: A arquitetura desta entidade está definida mas o corpo ainda não contém a instanciação do `Encrypt_FSM` com a lógica de conversão entre `std_logic_vector(127 downto 0)` e o tipo `matrix`. Essa ponte será a etapa de integração final.

---

## 🧪 Testbenches

Cada componente possui um testbench individual para validação isolada.

| Testbench                                            | Componente testado         | Descrição                                  |
|------------------------------------------------------|----------------------------|--------------------------------------------|
| [`sbox_tb.vhd`](ImplementacaoIterativa/tb/sbox_tb.vhd) | S-Box | Validação da tabela de substituição |
| [`SubBytes_ShiftRows_tb.vhd`](ImplementacaoIterativa/tb/SubBytes_ShiftRows_tb.vhd) | SubBytes + ShiftRows | Valida a fusão das duas operações |
| [`MixColumns_tb.vhd`](ImplementacaoIterativa/tb/MixColumns_tb.vhd) | MixColumns | Valida a multiplicação matricial em GF(2⁸) |
| [`KeySchedules_tb.vhd`](ImplementacaoIterativa/tb/KeySchedules_tb.vhd) | KeySchedule | Valida a expansão de 1 rodada de chave |
| [`KeySchedules_FSM_tb.vhd`](ImplementacaoIterativa/tb/KeySchedules_FSM_tb.vhd) | KeySchedules_FSM | Valida as 10 rodadas de expansão |
| [`Encrypt_FSM_tb.vhd`](ImplementacaoIterativa/tb/Encrypt_FSM_tb.vhd) | Encrypt_FSM | Teste de integração do AES-128 completo |

O testbench do `Encrypt_FSM` utiliza o vetor de teste oficial do NIST para validação.

---

## 📋 Vetor de Teste NIST (FIPS-197)

O documento **FIPS-197** (Federal Information Processing Standard Publication 197) define o AES e fornece vetores de teste oficiais. Este projeto utiliza o seguinte vetor:

```
Chave (Key):
  2B 7E 15 16 28 AE D2 A6 AB F7 15 88 09 CF 4F 3C

Texto Claro (Plaintext):
  32 43 F6 A8 88 5A 30 8D 31 31 98 A2 E0 37 07 34

Texto Cifrado Esperado (Ciphertext):
  39 25 84 1D 02 DC 09 FB DC 11 85 97 19 6A 0B 32
```

### Resultado esperado rodada a rodada

| Rodada | Após SubBytes+ShiftRows+MixColumns+AddRoundKey (State)      |
|--------|--------------------------------------------------------------|
| 0      | `19 A0 9A E9 3D F4 C6 F8 E3 E2 8D 48 BE 2B 2A 08` (apenas AddRoundKey) |
| 1      | `A4 68 6B 02 9C 9F 5B 6A 7F 35 EA 50 F2 2B 43 49` |
| 2      | `AA 61 82 68 8F DD D2 32 5F E3 4A 46 03 EF D2 9A` |
| 3      | `48 67 4D D6 6B EC E1 0D 53 B2 04 B1 F0 FE 44 30` |
| 4      | `E0 C8 D9 85 92 63 B1 B8 7F 63 35 BE E8 C0 50 01` |
| 5      | `F1 00 6F 55 C1 92 4C EF 78 41 29 A6 E8 99 FE 9D` |
| 6      | `26 0E 2E 17 3D 41 B7 7D E8 63 46 E0 12 E2 36 87` |
| 7      | `5A 41 42 B1 19 49 DC 1F A3 E0 19 65 7A 8C 04 0C` |
| 8      | `EA 04 65 85 83 45 5D 96 5C 33 98 B0 F0 2D AD C5` |
| 9      | `EB 59 8B 1B 40 2E A1 C3 F2 38 13 42 1E 84 E7 D2` |
| 10     | `39 25 84 1D 02 DC 09 FB DC 11 85 97 19 6A 0B 32` ← **Ciphertext final** |

---

## 📂 Estrutura de Diretórios

```
AES-fpga-IC/
├── README.md                          ← Este arquivo
├── LICENSE                            ← Licença do projeto
│
└── ImplementacaoIterativa/            ← Implementação iterativa do AES-128
    │
    ├── aes_iterativo.vhd              ← Entidade top-level
    ├── aes_package.vhd                ← Pacote: tipos e funções AES
    ├── aes_iterativo.qpf              ← Projeto Quartus
    ├── aes_iterativo.qsf              ← Configurações Quartus
    │
    ├── rtl/                           ← Componentes de hardware (síntese)
    │   ├── sbox.vhd                   ← S-Box (lookup table)
    │   ├── SubBytes_ShiftRows.vhd     ← SubBytes + ShiftRows fundidos
    │   ├── MixColumns.vhd             ← Mistura de colunas (GF(2⁸))
    │   ├── AddRoundKey.vhd            ← XOR com chave da rodada
    │   ├── KeySchedule.vhd            ← Expansão de 1 rodada de chave
    │   ├── KeySchedules_FSM.vhd       ← Orquestrador de expansão de chave
    │   └── Encrypt_FSM.vhd            ← FSM principal de encriptação
    │
    ├── tb/                            ← Testbenches
    │   ├── sbox_tb.vhd
    │   ├── SubBytes_ShiftRows_tb.vhd
    │   ├── MixColumns_tb.vhd
    │   ├── KeySchedules_tb.vhd
    │   ├── KeySchedules_FSM_tb.vhd
    │   └── Encrypt_FSM_tb.vhd
    │
    ├── simulation/                    ← Arquivos de simulação
    │   └── questa/
    │
    └── output_files/                  ← Saídas de síntese/compilação
```

---

## 📜 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
