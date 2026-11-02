import '../../core/widgets/kibo_modal.dart';
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
    final action = await showKiboModalSheet<String>(
      context: context,
      builder: (context) => KiboSheet(
        title: 'Actions du message',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              KiboSheetAction(
                label: 'Modifier',
                icon: Icons.edit_outlined,
                onTap: () => Navigator.pop(context, 'edit'),
              ),
            if (onReport != null)
              KiboSheetAction(
                label: 'Signaler',
                icon: Icons.flag_outlined,
                onTap: () => Navigator.pop(context, 'report'),
              ),
            KiboSheetAction(
              label: 'Copier',
              icon: Icons.copy_outlined,
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            if (onDelete != null)
              KiboSheetAction(
                label: 'Supprimer',
                icon: Icons.delete_outline,
                destructive: true,
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
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
                      IconButton(
                        key: ValueKey('message-actions-${message.id}'),
                        tooltip: 'Actions du message',
                        icon: const Icon(Icons.more_horiz, size: 20),
                        onPressed: () => _showActions(context),
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
  Widget build(BuildContext context) => KiboDialog(
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
