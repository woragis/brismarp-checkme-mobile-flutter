import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/care/care_controller.dart';
import '../../domain/care/phase.dart';
import '../theme/colors.dart';

class _GuideStep {
  const _GuideStep(this.title, this.description);

  final String title;
  final String description;
}

const _guides = <String, List<_GuideStep>>{
  '/cuidar': [
    _GuideStep('Comece pela sua necessidade', 'A orientação opcional ajuda a encontrar uma especialidade. Ela não faz diagnóstico nem substitui a conversa com o profissional.'),
    _GuideStep('Escolha o tipo de atendimento', 'Você pode procurar uma teleconsulta ou encontrar parceiros para atendimento presencial.'),
    _GuideStep('Explore as opções', 'Especialidades, descontos e perguntas frequentes ajudam você a conhecer os serviços disponíveis.'),
  ],
  '/cuidar/especialidades': [
    _GuideStep('Conheça as especialidades', 'Consulte as áreas de atendimento e use as informações para decidir qual profissional procurar.'),
  ],
  '/cuidar/online': [
    _GuideStep('Encontre uma teleconsulta', 'Escolha uma especialidade e veja profissionais e horários disponíveis após entrar na conta.'),
    _GuideStep('Confirme o pedido', 'Escolha um horário e confirme o envio. O profissional ainda precisa aceitar para a consulta ficar confirmada.'),
    _GuideStep('Abra a videochamada', 'Depois da confirmação, o acesso à plataforma externa aparece na área Consultas.'),
  ],
  '/cuidar/rede': [
    _GuideStep('Busque atendimento presencial', 'Pesquise por cidade ou use sua localização para encontrar parceiros próximos.'),
    _GuideStep('Escolha como continuar', 'Confira endereço e serviços, ligue para o local ou abra o mapa. Se negar a localização, você ainda pode buscar por cidade.'),
  ],
  '/cuidar/descontos': [
    _GuideStep('Consulte os descontos', 'Confira os benefícios e os parceiros associados. Confirme as condições diretamente com o local quando necessário.'),
  ],
  '/cuidar/faq': [
    _GuideStep('Encontre uma resposta', 'Use as perguntas frequentes para entender os serviços, a conta e os próximos passos.'),
  ],
  '/consultas': [
    _GuideStep('Acompanhe seus pedidos', 'Veja solicitações aguardando resposta, consultas confirmadas e pedidos recusados.'),
    _GuideStep('Responda a uma proposta', 'Se o profissional sugerir outro horário, aceite ou recuse. A consulta só fica confirmada quando vocês concordam.'),
    _GuideStep('Entre na chamada', 'Use o botão de videochamada quando a consulta estiver confirmada e liberada.'),
  ],
  '/planos': [
    _GuideStep('Compare os planos', 'Confira os benefícios e valores disponíveis.'),
    _GuideStep('Use um cupom', 'Informe o código promocional e valide antes de continuar.'),
    _GuideStep('Conclua a contratação', 'Entre na conta para contratar e acompanhar a assinatura.'),
  ],
  '/conta': [
    _GuideStep('Gerencie sua conta', 'Acesse perfil, ficha, dependentes e opções de privacidade.'),
  ],
  '/conta/porta': [
    _GuideStep('Navegue pela sua conta', 'Esta área reúne os atalhos para ficha, família e gerenciamento de dados.'),
  ],
  '/conta/ficha': [
    _GuideStep('Atualize sua ficha', 'Confira e mantenha atualizados os dados pessoais disponíveis na conta.'),
  ],
  '/conta/familia': [
    _GuideStep('Gerencie dependentes', 'Adicione ou remova pessoas vinculadas à sua conta conforme necessário.'),
  ],
  '/conta/dados': [
    _GuideStep('Seus dados e privacidade', 'Consulte as opções para exportar e gerenciar seus dados pessoais.'),
  ],
  '/conta/excluir': [
    _GuideStep('Excluir conta', 'Revise as informações e consequências antes de confirmar. A exclusão pode ser irreversível.'),
  ],
};

const _routeTitles = <String, String>{
  '/cuidar': 'CUIDAR',
  '/cuidar/especialidades': 'ESPECIALIDADES',
  '/cuidar/online': 'CONSULTA ONLINE',
  '/cuidar/rede': 'REDE PRESENCIAL',
  '/cuidar/descontos': 'DESCONTOS',
  '/cuidar/faq': 'PERGUNTAS FREQUENTES',
  '/consultas': 'CONSULTAS',
  '/planos': 'PLANOS',
  '/conta': 'CONTA',
  '/conta/porta': 'ACESSO À CONTA',
  '/conta/ficha': 'FICHA',
  '/conta/familia': 'FAMÍLIA',
  '/conta/dados': 'DADOS E PRIVACIDADE',
  '/conta/excluir': 'EXCLUSÃO DA CONTA',
};

const _careGuides = <String, List<_GuideStep>>{
  'orientation': [
    _GuideStep('Explique sua dúvida', 'Conte em poucas palavras qual tipo de atendimento procura. Evite incluir informações que não sejam necessárias para escolher a especialidade.'),
    _GuideStep('Receba uma sugestão', 'A orientação indica uma especialidade possível. Ela não faz diagnóstico nem anamnese.'),
  ],
  'next-step': [
    _GuideStep('Entenda a sugestão', 'O próximo passo recomendado ajuda a encontrar o tipo de profissional que pode atender você.'),
    _GuideStep('Continue para a busca', 'Toque em Ver profissionais para conferir opções e horários. A avaliação acontece com o profissional durante a consulta.'),
  ],
  'professionals': [
    _GuideStep('Compare profissionais', 'Confira os profissionais disponíveis para a especialidade sugerida.'),
    _GuideStep('Escolha um horário', 'Selecione um profissional para consultar os horários livres e pedir uma consulta.'),
  ],
  'slots': [
    _GuideStep('Escolha um horário livre', 'A lista mostra horários que podem ser solicitados com o profissional selecionado.'),
    _GuideStep('Envie o pedido', 'Confirme o envio. O profissional recebe a solicitação e precisa aceitar; se propuser outro horário, você decide se aceita.'),
  ],
  'account': [
    _GuideStep('Entre ou crie sua conta', 'A conta protege o acesso aos profissionais disponíveis, aos pedidos e às consultas.'),
    _GuideStep('Continue sem e-mail no modo dev', 'Em desenvolvimento, a conta fica pronta sem confirmação de e-mail. No ambiente publicado, siga a etapa de confirmação apresentada pelo sistema.'),
  ],
  'emergency': [
    _GuideStep('Procure ajuda urgente', 'Este aviso indica que você deve buscar atendimento de emergência agora. O CheckMe não substitui os serviços de urgência.'),
    _GuideStep('Use o contato disponível', 'Se houver um canal de emergência exibido na tela, use-o para procurar ajuda imediatamente.'),
  ],
};

class TutorialButton extends ConsumerWidget {
  const TutorialButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final care = ref.watch(careControllerProvider);
    final stage = care.sheetOpen || care.phase is CarePedindoConta
        ? 'account'
        : switch (care.phase) {
            CareDescrevendo() => 'orientation',
            CareProximoPasso() => 'next-step',
            CareEscolhendoProfissional() => 'professionals',
            CareEscolhendoHorario() => 'slots',
            CareGrave() => 'emergency',
            CareVisitante() || CareEmPaz() => null,
            CarePedindoConta() => 'account',
          };
    return FloatingActionButton.small(
      heroTag: 'checkme-tutorial-help',
      tooltip: 'Como funciona esta tela?',
      backgroundColor: CheckmeColors.navy,
      foregroundColor: Colors.white,
      onPressed: () => _showTutorial(context, stage),
      child: const Icon(Icons.help_outline),
    );
  }

  Future<void> _showTutorial(BuildContext context, String? stage) async {
    final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final guide = stage == null
        ? (_guides[path] ?? _guides['/cuidar']!)
        : _careGuides[stage]!;
    final routeTitle = stage == null
        ? (_routeTitles[path] ?? 'CHECKME')
        : switch (stage) {
            'orientation' => 'ORIENTAÇÃO',
            'next-step' => 'PRÓXIMO PASSO',
            'professionals' => 'PROFISSIONAIS',
            'slots' => 'HORÁRIOS',
            'account' => 'ACESSO À CONTA',
            'emergency' => 'AJUDA URGENTE',
            _ => 'CUIDAR',
          };
    var index = 0;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) {
          final step = guide[index];
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('GUIA VISUAL · $routeTitle',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: CheckmeColors.care, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(sheetContext), tooltip: 'Fechar', icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(step.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(guide.length, (i) => Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: i == guide.length - 1 ? 0 : 6),
                      decoration: BoxDecoration(color: i <= index ? CheckmeColors.care : CheckmeColors.borda, borderRadius: BorderRadius.circular(8)),
                    ),
                  )),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 66,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: guide.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => Container(
                      width: 118,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: i == index ? CheckmeColors.lavanda : Colors.white,
                        border: Border.all(color: i == index ? CheckmeColors.care : CheckmeColors.borda),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ETAPA ${i + 1}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: CheckmeColors.care, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Expanded(child: Text(guide[i].title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(step.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    TextButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Pular guia')),
                    const Spacer(),
                    if (index > 0)
                      OutlinedButton(onPressed: () => setState(() => index -= 1), child: const Text('Anterior')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (index == guide.length - 1) {
                          Navigator.pop(sheetContext);
                        } else {
                          setState(() => index += 1);
                        }
                      },
                      child: Text(index == guide.length - 1 ? 'Concluir' : 'Próximo'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
