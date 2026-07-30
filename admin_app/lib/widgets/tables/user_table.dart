import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/admin_theme.dart';
import '../../models/admin_user.dart';

class UserTable extends StatelessWidget {
  const UserTable({
    super.key,
    required this.users,
    required this.onEdit,
    required this.onToggleActive,
  });

  final List<AdminUser> users;
  final ValueChanged<AdminUser> onEdit;
  final void Function(AdminUser user, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy');
    if (users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Nenhum usuário encontrado.',
            style: TextStyle(color: AdminTheme.muted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AdminTheme.text,
        ),
        dataTextStyle: const TextStyle(color: AdminTheme.text),
        columns: const [
          DataColumn(label: Text('Usuário')),
          DataColumn(label: Text('Empresa')),
          DataColumn(label: Text('Matrícula')),
          DataColumn(label: Text('Permissão')),
          DataColumn(label: Text('Cargo')),
          DataColumn(label: Text('Criado em')),
          DataColumn(label: Text('Ativo')),
          DataColumn(label: Text('Ações')),
        ],
        rows: users.map((user) {
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 240,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AdminTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(
                    user.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(user.matricula)),
              DataCell(Text(user.permissionLabel)),
              DataCell(Text(user.role)),
              DataCell(
                Text(
                  user.createdAt == null ? '-' : date.format(user.createdAt!),
                ),
              ),
              DataCell(
                Switch(
                  value: user.active,
                  onChanged: (value) => onToggleActive(user, value),
                ),
              ),
              DataCell(
                IconButton(
                  onPressed: () => onEdit(user),
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Editar usuário',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
