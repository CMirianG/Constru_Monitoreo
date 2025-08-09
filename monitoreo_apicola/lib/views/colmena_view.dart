import 'package:flutter/material.dart';
import '../controllers/colmena_controller.dart';
import '../models/colmena_model.dart';

/// Vista para mostrar y gestionar la información de la colmena.
/// Alineada con el RF-003: Registrar y actualizar información de una única colmena.
class ColmenaView extends StatefulWidget {
  const ColmenaView({super.key});

  @override
  State<ColmenaView> createState() => _ColmenaViewState();
}

class _ColmenaViewState extends State<ColmenaView> {
  final ColmenaController _colmenaController = ColmenaController();

  // Controladores para los campos del formulario
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  bool _cargando = false;
  List<Colmena> _colmenas = [];

  @override
  void initState() {
    super.initState();
    _cargarColmenas();
  }

  /// Obtiene la lista de colmenas desde Firestore.
  Future<void> _cargarColmenas() async {
    setState(() => _cargando = true);
    try {
      final colmenas = await _colmenaController.getColmenas();
      setState(() {
        _colmenas = colmenas;
      });
    } catch (e) {
      debugPrint("Error al cargar colmenas: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  /// Guarda una nueva colmena en Firestore.
  Future<void> _guardarColmena() async {
    if (_ubicacionController.text.isEmpty ||
        _estadoController.text.isEmpty ||
        _descripcionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    final nuevaColmena = Colmena(
      id: '',
      ubicacion: _ubicacionController.text.trim(),
      estado: _estadoController.text.trim(),
      descripcionTecnica: _descripcionController.text.trim(),
    );

    try {
      await _colmenaController.addColmena(nuevaColmena);
      await _cargarColmenas();
      Navigator.pop(context); // Cierra el formulario
    } catch (e) {
      debugPrint("Error al guardar colmena: $e");
    }
  }

  /// Actualiza una colmena existente.
  Future<void> _actualizarColmena(Colmena colmena) async {
    try {
      await _colmenaController.updateColmena(colmena);
      await _cargarColmenas();
    } catch (e) {
      debugPrint("Error al actualizar colmena: $e");
    }
  }

  /// Elimina una colmena por su ID.
  Future<void> _eliminarColmena(String id) async {
    try {
      await _colmenaController.deleteColmena(id);
      await _cargarColmenas();
    } catch (e) {
      debugPrint("Error al eliminar colmena: $e");
    }
  }

  /// Abre el formulario para crear una nueva colmena.
  void _abrirFormularioNueva() {
    _ubicacionController.clear();
    _estadoController.clear();
    _descripcionController.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nueva Colmena"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ubicacionController,
              decoration: const InputDecoration(labelText: "Ubicación"),
            ),
            TextField(
              controller: _estadoController,
              decoration: const InputDecoration(labelText: "Estado"),
            ),
            TextField(
              controller: _descripcionController,
              decoration:
                  const InputDecoration(labelText: "Descripción Técnica"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: _guardarColmena,
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Colmena"),
        backgroundColor: Colors.teal,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _colmenas.length,
              itemBuilder: (context, index) {
                final colmena = _colmenas[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(colmena.ubicacion),
                    subtitle: Text(
                      "Estado: ${colmena.estado}\nDescripción: ${colmena.descripcionTecnica}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            // Se podría abrir un formulario de edición aquí
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarColmena(colmena.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormularioNueva,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
