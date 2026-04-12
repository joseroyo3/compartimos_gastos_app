import 'package:compartimos_gastos/controllers/group_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../controllers/pay_controller.dart';
import '../../../controllers/themes_controller.dart';
import '../../../models/group_model.dart';
import '../../../widgets/appbar_custom.dart';

class SettingsGroupScreen extends StatefulWidget {
  final GroupModel groupModel;

  const SettingsGroupScreen({super.key, required this.groupModel});

  @override
  State<SettingsGroupScreen> createState() => _SettingsGroupScreenState();
}

class _SettingsGroupScreenState extends State<SettingsGroupScreen> {
  final PayController _payController = PayController();
  final GroupController _groupController = GroupController();
  late GroupModel _currentGroup;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.groupModel;
  }

  Future<void> _refreshGroup() async {
    final updated = await _groupController.obtenerGrupo(_currentGroup.id);
    if (updated != null && mounted) {
      setState(() {
        _currentGroup = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color colorGrupo = Color(_currentGroup.colorValue);

    return Theme(
      data: ThemeController.crearTema(colorGrupo),
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Ajustes del Grupo',
          showLogout: false,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CABECERA: INFO DEL GRUPO
                  _buildHeader(colorGrupo),
                  const SizedBox(height: 32),

                  // SECCIÓN: INVITAR
                  _buildSectionTitle("Acceso y Código"),
                  const SizedBox(height: 12),
                  _buildInviteCard(),
                  const SizedBox(height: 32),

                  // SECCIÓN: MIEMBROS
                  _buildSectionTitle("Gestión de Miembros"),
                  const SizedBox(height: 12),
                  _buildMembersManager(),
                  const SizedBox(height: 48),

                  // SECCIÓN: ACCIONES PELIGROSAS
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Zona de Peligro", color: Colors.red),
                  const SizedBox(height: 12),
                  const Text(
                    "Ten cuidado, estas acciones borrarán datos permanentemente.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _buildDeleteAllButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color ?? Colors.blueGrey.shade700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(Icons.group, size: 40, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              _currentGroup.nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _mostrarDialogoEditarGrupo,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text("Editar nombre o color"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCard() {
    return Card(
      elevation: 0,
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Invita a nuevos miembros compartiendo este código identificador:",
              style: TextStyle(fontSize: 14, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _currentGroup.id,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blueGrey.shade900,
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 20),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.blueGrey),
                    onPressed: () => _copiarAlPortapapeles(context, _currentGroup.id),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersManager() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ..._currentGroup.miembros.entries.map((entry) {
            final uid = entry.key;
            final nombre = entry.value;
            final isCreator = uid == _currentGroup.creadoPor;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(nombre[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text(
                nombre,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(isCreator ? "Administrador" : "Miembro del grupo"),
              trailing: isCreator 
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.star, color: Colors.amber, size: 16),
                  )
                : IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    onPressed: () => _confirmarEliminarMiembro(uid, nombre),
                  ),
            );
          }),
          const Divider(height: 1),
          _buildActionListTile(
            icon: Icons.person_add_alt_1_rounded,
            title: "Crear miembro temporal",
            subtitle: "Para personas sin la app",
            color: Colors.orange,
            onTap: _mostrarDialogoNuevoInvitado,
          ),
          _buildActionListTile(
            icon: Icons.alternate_email_rounded,
            title: "Vincular por Email",
            subtitle: "Usuarios con cuenta registrada",
            color: Colors.green,
            onTap: _mostrarDialogoAgregarMiembro,
          ),
        ],
      ),
    );
  }

  Widget _buildActionListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
      trailing: Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5)),
    );
  }

  Widget _buildDeleteAllButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.red,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.shade100, width: 2),
        ),
      ),
      icon: const Icon(Icons.delete_sweep_rounded),
      label: const Text("RESETEAR TODOS LOS GASTOS", style: TextStyle(fontWeight: FontWeight.bold)),
      onPressed: () => _confirmarBorradoTotal(context),
    );
  }

  void _copiarAlPortapapeles(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Código copiado")),
    );
  }

  void _mostrarDialogoEditarGrupo() {
    final nameController = TextEditingController(text: _currentGroup.nombre);
    Color selectedColor = Color(_currentGroup.colorValue);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Personalizar Grupo"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nombre del grupo",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Color del tema", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ThemeController.groupColors.map((item) {
                    final color = item['color'] as Color;
                    final isSelected = color.value == selectedColor.value;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected 
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                          ],
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevoNombre = nameController.text.trim();
                if (nuevoNombre.isEmpty) return;

                Navigator.pop(dialogContext);
                setState(() => _isLoading = true);

                try {
                  await _groupController.actualizarGrupo(_currentGroup.id, {
                    'nombre': nuevoNombre,
                    'color': selectedColor.value,
                  });
                  await _refreshGroup();
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Grupo actualizado")),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoAgregarMiembro() {
    final emailController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Vincular Usuario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Añade a alguien que ya tenga la cuenta creada introduciendo su email."),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email del usuario",
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              
              try {
                await _groupController.agregarMiembroPorEmail(_currentGroup.id, email);
                await _refreshGroup();
                messenger.showSnackBar(
                  const SnackBar(content: Text("Usuario añadido")),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoNuevoInvitado() {
    final nameController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Miembro Temporal"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ideal para personas que no usan la app directamente."),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nombre",
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nameController.text.trim();
              if (nombre.isEmpty) return;

              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);

              try {
                await _groupController.agregarMiembroInvitado(_currentGroup.id, nombre);
                await _refreshGroup();
                messenger.showSnackBar(
                  const SnackBar(content: Text("Miembro temporal creado")),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("Crear"),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminarMiembro(String uid, String nombre) {
    final messenger = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("¿Eliminar miembro?"),
        content: Text("¿Estás seguro de que quieres quitar a $nombre del grupo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              
              try {
                // 1. Comprobar si tiene gastos
                final tieneGastos = await _groupController.tieneGastosAsociados(_currentGroup.id, uid);
                
                if (tieneGastos) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("No se puede eliminar: Este usuario tiene gastos o deudas asociadas."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // 2. Si no tiene, procedemos
                await _groupController.eliminarMiembro(_currentGroup.id, uid);
                await _refreshGroup();
                messenger.showSnackBar(
                  const SnackBar(content: Text("Miembro eliminado")),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  void _confirmarBorradoTotal(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("¿Resetear Grupo?"),
        content: const Text(
          "Se borrarán todos los gastos, deudas y la lista de la compra. Esta acción es irreversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);

              try {
                await _payController.borrarTodosLosDatosDelGrupo(_currentGroup.id);
                messenger.showSnackBar(
                  const SnackBar(content: Text("Gastos reseteados")),
                );
                if (mounted) Navigator.pop(context);
              } catch (e) {
                print(e);
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("Sí, resetear todo"),
          ),
        ],
      ),
    );
  }
}
