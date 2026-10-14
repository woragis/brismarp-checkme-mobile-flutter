# CheckMe — app do paciente (Flutter)

Recorte 1: **Cuidar + Orientação**. Mapa em [`arquitetura/frontend/CUIDAR-ORIENTACAO.md`](../arquitetura/frontend/CUIDAR-ORIENTACAO.md).

O Expo em `checkme/mobile` está **congelado**. Não porta telas de lá.

## Rodar

API no ar (`make db-up` e `make backend` na raiz do CheckMe). Depois:

```bash
cd flutter-mobile
flutter pub get
flutter run
```

URL da API:

- `--dart-define=API_URL=http://localhost:8000` (iOS simulator, Linux)
- emulador Android usa `http://10.0.2.2:8000` por padrão

Health: `GET /health/ready`. Chat: `POST /api/v1/chat` (titular autenticado).

Com a API ready, o cliente HTTP do recorte 1:

```bash
dart run tool/smoke_api.dart
```

Seed de login: `patient@checkme.local` / `checkme-patient-2026`. Grave sem IA: `dor no peito e falta de ar`. Leve em development: `qa triagem leve`.

Celular físico: `--dart-define=API_URL=http://IP-DA-MAQUINA:8000`.

## Recorte 1

Quatro abas: Cuidar, Consultas, Planos e Conta (menu de uma linha por função).

- Visitante vê o hub e começa a orientação sem conta.
- Login no momento do valor (sheet), com checkbox LGPD.
- `ALERTA_GRAVE` → tela de urgência (SAMU 192 / WhatsApp). Sem agendar. Sem SOAP.
- `LEVE` / `MODERADO` → beat do check, com o relato e o próximo passo. A pessoa toca em Ver profissionais. Sem auto-navegar para a agenda.
- Emergência nunca bloqueada por login.

## Pasta

```
lib/
  domain/
  application/
  infrastructure/
  presentation/
```

Telas não falam HTTP. Erros por `error.code`.

## Identidade visual

As quatro logos PNG oficiais ficam em `assets/brand/`, com margens transparentes
ajustadas a partir dos originais em `../assets/`. `Logo` seleciona extended ou
short via `layout`, e a variante para fundo escuro via `inverted: true`.
O cabeçalho de Cuidar usa a marca clara sobre roxo escuro.

A paleta está centralizada em `lib/presentation/theme/colors.dart`: roxo para
ações principais, ciano para destaques e lavanda para superfícies. O ciano de
texto é mais escuro para leitura em branco; as cores de alerta e sucesso mantêm
seu significado.
