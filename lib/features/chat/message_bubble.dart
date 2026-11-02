import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat_repository.dart';
import '../auth/auth_controller.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    this.onEdit,
    this.onDelete,
    this.onReport,
  });
  final ChatMessage message;
  final bool mine;
  final VoidCallback? onEdit, onDelete, onReport;
  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Actions du message',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (onEdit != null)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Modifier'),
                  onTap: () => Navigator.pop(context, 'edit'),
                ),
              if (onDelete != null)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Supprimer'),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
              if (onReport != null)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Signaler'),
                  onTap: () => Navigator.pop(context, 'report'),
                ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copier'),
                onTap: () => Navigator.pop(context, 'copy'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') onEdit?.call();
    if (action == 'delete') onDelete?.call();
    if (action == 'report') onReport?.call();
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: message.content));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final date = message.createdAt.toLocal();
    final removed = message.deletedAt != null || message.senderDeleted;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .88,
        ),
        child: GestureDetector(
          key: ValueKey('message-long-press-${message.id}'),
          behavior: HitTestBehavior.opaque,
          onLongPress: onEdit != null || onDelete != null || onReport != null
              ? () => _showActions(context)
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 10),
            decoration: BoxDecoration(
              color: mine
                  ? colors.primaryContainer
                  : colors.surfaceContainerLow,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(mine ? 20 : 5),
                bottomRight: Radius.circular(mine ? 5 : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        mine ? 'Vous' : 'Votre interlocuteur',
                        style: text.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (onEdit != null || onDelete != null || onReport != null)
                      PopupMenuButton<String>(
                        key: ValueKey('message-actions-${message.id}'),
                        tooltip: 'Actions du message',
                        icon: const Icon(Icons.more_horiz, size: 20),
                        onSelected: (value) {
                          if (value == 'edit') onEdit?.call();
                          if (value == 'delete') onDelete?.call();
                          if (value == 'report') onReport?.call();
                        },
                        itemBuilder: (_) => [
                          if (onReport != null)
                            const PopupMenuItem(
                              value: 'report',
                              child: ListTile(
                                leading: Icon(Icons.flag_outlined),
                                title: Text('Signaler'),
                              ),
                            ),
                          if (onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Modifier'),
                              ),
                            ),
                          if (onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Supprimer'),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (removed)
                  Text(
                    message.senderDeleted
                        ? 'Message anonymisé'
                        : 'Message supprimé',
                    style: text.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: colors.onSurfaceVariant,
                    ),
                  )
                else if (onEdit != null || onDelete != null)
                  Text(message.content, style: text.bodyMedium)
                else
                  SelectableText(message.content, style: text.bodyMedium),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                      style: text.labelSmall,
                    ),
                    if (message.editedAt != null && !removed)
                      Text('Modifié', style: text.labelSmall),
                    if (mine && !removed)
                      Text(
                        message.readAt == null ? 'Envoyé' : 'Lu',
                        style: text.labelSmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditMessageDialog extends StatefulWidget {
  const EditMessageDialog({
    super.key,
    required this.content,
    this.auth,
    this.ownerId,
  });
  final String content;
  final AuthController? auth;
  final String? ownerId;
  @override
  State<EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<EditMessageDialog> {
  late final _text = TextEditingController(text: widget.content);
  final _form = GlobalKey<FormState>();
  bool _invalid = false;
  @override
  void initState() {
    super.initState();
    widget.auth?.addListener(_sessionChanged);
    _invalid =
        widget.auth != null && widget.auth!.identity?.id != widget.ownerId;
    if (_invalid) _text.clear();
  }

  void _sessionChanged() {
    if (widget.auth?.identity?.id != widget.ownerId && !_invalid) {
      _text.clear();
      if (mounted) setState(() => _invalid = true);
    }
  }

  @override
  void dispose() {
    widget.auth?.removeListener(_sessionChanged);
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    icon: const Icon(Icons.edit_outlined),
    title: const Text('Modifier le message'),
    content: _invalid
        ? const Text('Session modifiée. Fermez ce formulaire.')
        : Form(
            key: _form,
            child: TextFormField(
              key: const ValueKey('edit-message-content'),
              controller: _text,
              autofocus: true,
              minLines: 2,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Votre message'),
              validator: (value) => validateMessage(value ?? ''),
            ),
          ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: _invalid
            ? null
            : () {
                if (_form.currentState!.validate()) {
                  Navigator.pop(context, _text.text);
                }
              },
        child: const Text('Enregistrer'),
      ),
    ],
  );
}
