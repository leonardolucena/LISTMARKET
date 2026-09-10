import 'package:flutter/material.dart';

import '../services/shopping_list_repository.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _repository = ShoppingListRepository.instance;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSaving = false;

  static const _examples = [
    'Lista de compras',
    'Compra semanal',
    'Compra mensal',
    'Compra quinzenal',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canSubmit => _controller.text.trim().isNotEmpty && !_isSaving;

  void _selectExample(String example) {
    _controller.text = example;
    _controller.selection = TextSelection.collapsed(offset: example.length);
    _focusNode.requestFocus();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSaving = true);

    await _repository.createList(_controller.text.trim());

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _canSubmit ? _submit : null,
        child: _isSaving
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.arrow_forward),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                  children: [
                    TextSpan(
                      text: 'Vamos começar!\n',
                      style: TextStyle(
                        fontSize: (Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.fontSize ??
                                28) +
                            1,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const TextSpan(text: 'Digite o nome da sua lista'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Exemplos:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _examples.map((example) {
                  final isSelected = _controller.text.trim() == example;

                  return FilterChip(
                    label: Text(example),
                    selected: isSelected,
                    onSelected: (_) => _selectExample(example),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
