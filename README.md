# CheckMe — app do paciente (Flutter)

App Flutter para iOS, Android e web. O visitante consulta informações gerais;
a lista de profissionais, horários disponíveis e dados privados da rede ficam
visíveis depois do login. A reserva exige uma conta autenticada.

## Executar localmente

Com a API disponível (`make db-up` e `make backend` na raiz):

```bash
cd flutter-mobile
flutter pub get
flutter run
```

A API local usa `http://localhost:8000` no Chrome/iOS/Linux e
`http://10.0.2.2:8000` no emulador Android. Para um celular físico, informe o IP
da máquina:

```bash
flutter run --dart-define=API_URL=http://IP-DA-MAQUINA:8000
```

Também há os atalhos `make flutter` e `make flutter-web` na raiz. O Flutter não é
incluído no Docker Compose.

## Confirmação de e-mail

No modo `APP_ENV=development`, novos usuários ficam verificados localmente e o
sistema não envia e-mails. Fora desse modo, a conta pode usar as áreas públicas,
mas precisa confirmar o e-mail para fazer ações protegidas, como pedir uma
consulta ou contratar um plano.

## Fluxos do paciente

- A orientação opcional ajuda a escolher uma especialidade. Não faz diagnóstico,
  anamnese, SOAP, resumo clínico ou prontuário.
- O paciente pode pesquisar diretamente, escolher um horário e enviar o pedido.
  O profissional precisa aceitar; se sugerir outro horário, o paciente decide
  se aceita.
- A videochamada abre um serviço externo pelo link associado à consulta. O
  CheckMe não incorpora a chamada.
- A rede presencial aceita localização ou seleção manual de cidade. A localização
  só é usada após autorização do sistema operacional.

O gateway de pagamento e os dados reais da rede são configurados na instalação
do cliente; a demonstração local usa dados e cobrança de demonstração.
