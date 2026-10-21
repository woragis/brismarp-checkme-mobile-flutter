import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/agenda/models.dart';
import '../../../infrastructure/api/checkme_api.dart';
import '../../theme/colors.dart';

class RedeScreen extends ConsumerStatefulWidget {
  const RedeScreen({super.key});

  @override
  ConsumerState<RedeScreen> createState() => _RedeScreenState();
}

class _RedeScreenState extends ConsumerState<RedeScreen> {
  static const _cidades = ['Maceió', 'Arapiraca', 'Penedo'];
  final _busca = TextEditingController();
  String _cidade = 'Maceió';
  List<ParceiroPresencial> _parceiros = const [];
  bool _carregando = false;
  bool _localizando = false;
  String? _erro;
  bool _porDistancia = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_carregarCidade);
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregarCidade() async {
    await _carregar(cidade: _cidade);
  }

  Future<void> _carregar({
    String cidade = '',
    double? latitude,
    double? longitude,
  }) async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final result = await ref
          .read(checkmeApiProvider)
          .redePresencial(
            cidade: cidade,
            latitude: latitude,
            longitude: longitude,
          );
      if (!mounted) return;
      setState(() {
        _parceiros = result;
        _carregando = false;
        _porDistancia = latitude != null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _parceiros = const [];
        _carregando = false;
        _erro = 'Não foi possível carregar a rede agora.';
      });
    }
  }

  Future<void> _usarLocalizacao() async {
    setState(() {
      _localizando = true;
      _erro = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(
          'Ative a localização do aparelho ou escolha uma cidade.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permita a localização ou escolha uma cidade.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      setState(() => _localizando = false);
      await _carregar(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _localizando = false;
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final termo = _busca.text.trim().toLowerCase();
    final itens = _parceiros
        .where(
          (p) =>
              termo.isEmpty ||
              p.nome.toLowerCase().contains(termo) ||
              p.especialidades.any((e) => e.toLowerCase().contains(termo)) ||
              p.servicos.any((e) => e.toLowerCase().contains(termo)),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Atendimento presencial')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Encontre médicos, clínicas e exames presenciais.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            value: _cidade,
            decoration: const InputDecoration(
              labelText: 'Cidade',
              border: OutlineInputBorder(),
            ),
            items: _cidades
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _cidade = value);
              _carregar(cidade: value);
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _localizando ? null : _usarLocalizacao,
            icon: _localizando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              _localizando ? 'Buscando localização…' : 'Usar minha localização',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _busca,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Especialidade, exame ou clínica',
              border: OutlineInputBorder(),
            ),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 12),
            Text(_erro!, style: const TextStyle(color: CheckmeColors.alerta)),
          ],
          const SizedBox(height: 18),
          if (_carregando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (itens.isEmpty)
            _Vazio(
              erro: _erro != null,
              porDistancia: _porDistancia,
              onCidade: () => _carregar(cidade: _cidade),
            )
          else ...[
            Text(
              _porDistancia ? 'Parceiros próximos' : 'Rede em $_cidade',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            for (final parceiro in itens) ...[
              _ParceiroCard(parceiro: parceiro),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 8),
          Text(
            'A distância aparece quando o endereço do parceiro está validado.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ParceiroCard extends StatelessWidget {
  const _ParceiroCard({required this.parceiro});
  final ParceiroPresencial parceiro;

  @override
  Widget build(BuildContext context) {
    final p = parceiro;
    final telefone = p.telefone.replaceAll(RegExp(r'[^0-9+]'), '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.nome, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${_tipo(p.tipo)} · ${p.cidade}/${p.uf}'),
            if (p.distanciaKm != null)
              Text('${p.distanciaKm!.toStringAsFixed(1)} km de você'),
            if (p.endereco.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(p.endereco),
              ),
            if (p.especialidades.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(p.especialidades.join(' · ')),
              ),
            if (p.servicos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(p.servicos.join(' · ')),
              ),
            if (telefone.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      launchUrl(Uri(scheme: 'tel', path: telefone)),
                  icon: const Icon(Icons.call_outlined),
                  label: Text(p.telefone),
                ),
              ),
            if (p.endereco.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  final destination = p.latitude != null && p.longitude != null
                      ? '${p.latitude},${p.longitude}'
                      : '${p.endereco}, ${p.cidade}, ${p.uf}';
                  launchUrl(
                    Uri.https('www.google.com', '/maps/search/', {
                      'api': '1',
                      'query': destination,
                    }),
                  );
                },
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Ver no mapa'),
              ),
          ],
        ),
      ),
    );
  }

  String _tipo(String tipo) => switch (tipo) {
    'clinica' => 'Clínica',
    'laboratorio' => 'Laboratório',
    'profissional' => 'Profissional',
    _ => 'Parceiro',
  };
}

class _Vazio extends StatelessWidget {
  const _Vazio({
    required this.erro,
    required this.porDistancia,
    required this.onCidade,
  });
  final bool erro;
  final bool porDistancia;
  final VoidCallback onCidade;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            erro
                ? 'Tente novamente em instantes.'
                : porDistancia
                ? 'Ainda não há parceiros com localização confirmada perto de você.'
                : 'Ainda não há parceiros cadastrados para esta cidade.',
          ),
          if (porDistancia)
            TextButton(
              onPressed: onCidade,
              child: const Text('Ver parceiros por cidade'),
            ),
        ],
      ),
    ),
  );
}
