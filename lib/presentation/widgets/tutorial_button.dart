import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/care/care_controller.dart';
import '../../domain/care/phase.dart';
import '../theme/colors.dart';

class _GuideStep {
  const _GuideStep(this.title, this.description, {this.target});

  final String title;
  final String description;
  final String? target;
}

class TutorialTargets {
  static final Map<String, GlobalKey> _keys = {};

  static GlobalKey keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);
}

class TutorialAnchor extends StatelessWidget {
  const TutorialAnchor({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: TutorialTargets.keyFor(id), child: child);
}

const _guides = <String, List<_GuideStep>>{
  '/cuidar': [
    _GuideStep(
      'Comece pela sua necessidade',
      'A orientação opcional ajuda a encontrar uma especialidade. Ela não faz diagnóstico nem substitui a conversa com o profissional.',
      target: 'home-orientation',
    ),
    _GuideStep(
      'Escolha o tipo de atendimento',
      'Você pode procurar uma teleconsulta ou encontrar parceiros para atendimento presencial.',
      target: 'home-online',
    ),
    _GuideStep(
      'Explore as opções',
      'Especialidades, descontos e perguntas frequentes ajudam você a conhecer os serviços disponíveis.',
      target: 'home-presencial',
    ),
  ],
  '/cuidar/especialidades': [
    _GuideStep(
      'Conheça as especialidades',
      'Consulte as áreas de atendimento e use as informações para decidir qual profissional procurar.',
    ),
  ],
  '/cuidar/online': [
    _GuideStep(
      'Escolha uma especialidade',
      'Selecione a área de atendimento que procura.',
      target: 'online-specialty',
    ),
    _GuideStep(
      'Busque um médico',
      'O app procura profissionais aprovados e horários livres para apresentar uma sugestão.',
      target: 'online-search',
    ),
    _GuideStep(
      'Confira a sugestão',
      'Veja o profissional e o horário propostos antes de confirmar o pedido.',
      target: 'online-suggestion',
    ),
    _GuideStep(
      'Confirme o pedido',
      'Envie o pedido. O profissional ainda precisa aceitar para a consulta ficar confirmada.',
      target: 'online-confirm',
    ),
    _GuideStep(
      'Abra a videochamada',
      'Depois da confirmação, o acesso à plataforma externa aparece na área Consultas.',
    ),
  ],
  '/cuidar/rede': [
    _GuideStep(
      'Busque por cidade',
      'Escolha uma cidade para encontrar os parceiros presenciais cadastrados.',
      target: 'network-city',
    ),
    _GuideStep(
      'Use sua localização',
      'Permita o acesso à localização para buscar parceiros próximos. Se negar, a busca por cidade continua disponível.',
      target: 'network-location',
    ),
    _GuideStep(
      'Abra os detalhes',
      'Confira os serviços e a distância. Você pode ligar para o parceiro ou abrir o mapa.',
      target: 'network-provider',
    ),
  ],
  '/cuidar/descontos': [
    _GuideStep(
      'Consulte os descontos',
      'Confira os benefícios e os parceiros associados. Confirme as condições diretamente com o local quando necessário.',
    ),
  ],
  '/cuidar/faq': [
    _GuideStep(
      'Encontre uma resposta',
      'Use as perguntas frequentes para entender os serviços, a conta e os próximos passos.',
    ),
  ],
  '/consultas': [
    _GuideStep(
      'Acompanhe seus pedidos',
      'Veja solicitações aguardando resposta, consultas confirmadas e pedidos recusados.',
      target: 'consultas-item',
    ),
    _GuideStep(
      'Responda a uma proposta',
      'Se o profissional sugerir outro horário, aceite ou recuse. A consulta só fica confirmada quando vocês concordam.',
      target: 'consultas-proposal',
    ),
    _GuideStep(
      'Entre na chamada',
      'Use o botão de videochamada quando a consulta estiver confirmada e liberada.',
      target: 'consultas-video',
    ),
  ],
  '/planos': [
    _GuideStep(
      'Compare os planos',
      'Confira os benefícios e valores disponíveis.',
      target: 'plans-option',
    ),
    _GuideStep(
      'Use um cupom',
      'Informe o código promocional e valide antes de continuar.',
      target: 'plans-coupon',
    ),
    _GuideStep(
      'Conclua a contratação',
      'Entre na conta para contratar e acompanhar a assinatura.',
      target: 'plans-subscribe',
    ),
  ],
  '/conta': [
    _GuideStep(
      'Gerencie sua conta',
      'Acesse perfil, ficha, dependentes e opções de privacidade.',
    ),
  ],
  '/conta/porta': [
    _GuideStep(
      'Navegue pela sua conta',
      'Esta área reúne os atalhos para ficha, família e gerenciamento de dados.',
    ),
  ],
  '/conta/ficha': [
    _GuideStep(
      'Atualize sua ficha',
      'Confira e mantenha atualizados os dados pessoais disponíveis na conta.',
    ),
  ],
  '/conta/familia': [
    _GuideStep(
      'Gerencie dependentes',
      'Adicione ou remova pessoas vinculadas à sua conta conforme necessário.',
    ),
  ],
  '/conta/dados': [
    _GuideStep(
      'Seus dados e privacidade',
      'Consulte as opções para exportar e gerenciar seus dados pessoais.',
    ),
  ],
  '/conta/excluir': [
    _GuideStep(
      'Excluir conta',
      'Revise as informações e consequências antes de confirmar. A exclusão pode ser irreversível.',
    ),
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
    _GuideStep(
      'Explique sua dúvida',
      'Conte em poucas palavras qual tipo de atendimento procura. Evite incluir informações que não sejam necessárias para escolher a especialidade.',
      target: 'orientation-input',
    ),
    _GuideStep(
      'Receba uma sugestão',
      'A orientação indica uma especialidade possível. Ela não faz diagnóstico nem anamnese.',
    ),
  ],
  'next-step': [
    _GuideStep(
      'Entenda a sugestão',
      'O próximo passo recomendado ajuda a encontrar o tipo de profissional que pode atender você.',
    ),
    _GuideStep(
      'Continue para a busca',
      'Toque em Ver profissionais para conferir opções e horários. A avaliação acontece com o profissional durante a consulta.',
      target: 'care-next-step',
    ),
  ],
  'professionals': [
    _GuideStep(
      'Compare profissionais',
      'Confira os profissionais disponíveis para a especialidade sugerida.',
      target: 'care-professional',
    ),
    _GuideStep(
      'Escolha um horário',
      'Selecione um profissional para consultar os horários livres e pedir uma consulta.',
    ),
  ],
  'slots': [
    _GuideStep(
      'Escolha um horário livre',
      'A lista mostra horários que podem ser solicitados com o profissional selecionado.',
      target: 'care-slot',
    ),
    _GuideStep(
      'Envie o pedido',
      'Confirme o envio. O profissional recebe a solicitação e precisa aceitar; se propuser outro horário, você decide se aceita.',
    ),
  ],
  'account': [
    _GuideStep(
      'Entre ou crie sua conta',
      'A conta protege o acesso aos profissionais disponíveis, aos pedidos e às consultas.',
      target: 'account-auth-action',
    ),
    _GuideStep(
      'Continue sem e-mail no modo dev',
      'Em desenvolvimento, a conta fica pronta sem confirmação de e-mail. No ambiente publicado, siga a etapa de confirmação apresentada pelo sistema.',
    ),
  ],
  'emergency': [
    _GuideStep(
      'Procure ajuda urgente',
      'Este aviso indica que você deve buscar atendimento de emergência agora. O CheckMe não substitui os serviços de urgência.',
    ),
    _GuideStep(
      'Use o contato disponível',
      'Se houver um canal de emergência exibido na tela, use-o para procurar ajuda imediatamente.',
    ),
  ],
};

class TutorialButton extends ConsumerWidget {
  const TutorialButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final care = ref.watch(careControllerProvider);
    final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final stage = path != '/cuidar'
        ? null
        : care.sheetOpen || care.phase is CarePedindoConta
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
      onPressed: () => _showTutorial(context, path, stage),
      child: const Icon(Icons.help_outline),
    );
  }

  Future<void> _showTutorial(
    BuildContext context,
    String path,
    String? stage,
  ) async {
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
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar guia visual',
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _TutorialOverlay(routeTitle: routeTitle, guide: guide),
    );
  }
}

class _TutorialOverlay extends StatefulWidget {
  const _TutorialOverlay({required this.routeTitle, required this.guide});

  final String routeTitle;
  final List<_GuideStep> guide;

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay> {
  int _index = 0;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());
  }

  void _goTo(int index) {
    setState(() {
      _index = index;
      _targetRect = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());
  }

  Future<void> _measureTarget() async {
    final target = widget.guide[_index].target;
    if (target == null) return;
    BuildContext? targetContext;
    for (
      var attempt = 0;
      attempt < 12 && targetContext == null && mounted;
      attempt++
    ) {
      targetContext = TutorialTargets.keyFor(target).currentContext;
      if (targetContext == null)
        await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    final resolvedContext = targetContext;
    if (resolvedContext == null || !mounted) return;
    try {
      await Scrollable.ensureVisible(
        resolvedContext,
        duration: const Duration(milliseconds: 250),
        alignment: .45,
      );
    } catch (_) {
      // A target outside a scrollable can still be spotlighted in place.
    }
    if (!mounted) return;
    final renderObject = resolvedContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final origin = renderObject.localToGlobal(Offset.zero);
    setState(() => _targetRect = origin & renderObject.size);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final step = widget.guide[_index];
    final targetRect = _targetRect;
    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Material(
        color: Colors.white,
        elevation: 18,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'GUIA VISUAL · ${widget.routeTitle}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: CheckmeColors.care,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Fechar',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(
                    widget.guide.length,
                    (i) => Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(
                          right: i == widget.guide.length - 1 ? 0 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: i <= _index
                              ? CheckmeColors.care
                              : CheckmeColors.borda,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 66,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.guide.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => Container(
                      width: 118,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: i == _index
                            ? CheckmeColors.lavanda
                            : Colors.white,
                        border: Border.all(
                          color: i == _index
                              ? CheckmeColors.care
                              : CheckmeColors.borda,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ETAPA ${i + 1}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: CheckmeColors.care,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              widget.guide[i].title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  step.description,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Pular guia'),
                    ),
                    const Spacer(),
                    if (_index > 0)
                      OutlinedButton(
                        onPressed: () => _goTo(_index - 1),
                        child: const Text('Anterior'),
                      ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (_index == widget.guide.length - 1) {
                          Navigator.pop(context);
                        } else {
                          _goTo(_index + 1);
                        }
                      },
                      child: Text(
                        _index == widget.guide.length - 1
                            ? 'Concluir'
                            : 'Próximo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      namesRoute: true,
      label: 'Guia visual: ${step.title}',
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _SpotlightPainter(targetRect)),
              ),
              if (targetRect == null)
                Positioned.fill(
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GestureDetector(onTap: () {}, child: card),
                      ),
                    ),
                  ),
                )
              else
                Positioned(
                  left: 16,
                  right: 16,
                  top: targetRect.center.dy > size.height / 2 ? 12 : null,
                  bottom: targetRect.center.dy > size.height / 2 ? null : 12,
                  child: SafeArea(
                    child: Center(
                      child: GestureDetector(onTap: () {}, child: card),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.target);

  final Rect? target;

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Paint()..color = CheckmeColors.roxoEscuro.withOpacity(.72);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (target != null) {
      path.addRRect(
        RRect.fromRectAndRadius(target!.inflate(6), const Radius.circular(14)),
      );
    }
    canvas.drawPath(path, shade);
    if (target != null) {
      final ring = Paint()
        ..color = CheckmeColors.ciano
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(target!.inflate(6), const Radius.circular(14)),
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.target != target;
}
