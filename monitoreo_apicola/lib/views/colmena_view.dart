import 'package:flutter/material.dart';
import '../controllers/colmena_controller.dart';
import '../models/colmena_model.dart';

/// Vista para la gestión de colmenas (RF-003)
/// Permite listar, registrar, actualizar y eliminar colmenas.
class ColmenaView extends StatefulWidget {
  const ColmenaView({super.key});

  @override
  State<ColmenaView> createState() => _ColmenaViewState();
}

class _ColmenaViewState extends State<ColmenaView> {
  final ColmenaController _colmenaController = ColmenaController();

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

  @override
  void dispose() {
    _ubicacionController.dispose();
    _estadoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarColmenas() async {
    setState(() => _cargando = true);
    try {
      final colmenas = await _colmenaController.getColmenas();
      setState(() => _colmenas = colmenas);
    } catch (e) {
      debugPrint("Error al cargar colmenas: $e");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error al guardar colmena: $e");
    }
  }

  Future<void> _actualizarColmena(Colmena colmena) async {
    try {
      await _colmenaController.updateColmena(colmena);
      await _cargarColmenas();
    } catch (e) {
      debugPrint("Error al actualizar colmena: $e");
    }
  }

  Future<void> _eliminarColmena(String id) async {
    try {
      await _colmenaController.deleteColmena(id);
      await _cargarColmenas();
    } catch (e) {
      debugPrint("Error al eliminar colmena: $e");
    }
  }

//esto es una prueba
  void _abrirFormularioNueva() {
    _ubicacionController.clear();
    _estadoController.clear();
    _descripcionController.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nueva Colmena"),
        content: SingleChildScrollView(
          child: Column(
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

  void _abrirFormularioEdicion(Colmena colmena) {
    _ubicacionController.text = colmena.ubicacion;
    _estadoController.text = colmena.estado;
    _descripcionController.text = colmena.descripcionTecnica;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Colmena"),
        content: SingleChildScrollView(
          child: Column(
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final colmenaEditada = Colmena(
                id: colmena.id,
                ubicacion: _ubicacionController.text.trim(),
                estado: _estadoController.text.trim(),
                descripcionTecnica: _descripcionController.text.trim(),
              );
              _actualizarColmena(colmenaEditada);
              Navigator.pop(context);
            },
            child: const Text("Actualizar"),
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
                          onPressed: () => _abrirFormularioEdicion(colmena),
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
