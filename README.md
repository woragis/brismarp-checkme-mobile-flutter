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

## Recorte 1

Três abas: Cuidar (este recorte), Consultas e Conta (placeholders).

- Visitante vê o hub e começa a orientação sem conta.
- Login no momento do valor (sheet), com checkbox LGPD.
- `ALERTA_GRAVE` → tela de urgência (SAMU 192 / WhatsApp). Sem agendar. Sem SOAP.
- `LEVE` / `MODERADO` → beat do check. Sem auto-navegar para agenda.
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
