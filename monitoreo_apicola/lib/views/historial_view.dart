import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LeerHistorialView extends StatefulWidget {
  const LeerHistorialView({super.key});

  @override
  State<LeerHistorialView> createState() => _LeerHistorialViewState();
}

class _LeerHistorialViewState extends State<LeerHistorialView> {
  bool _vistaCompacta = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("📘 Historial de Lecturas"),
        backgroundColor: Colors.teal[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_vistaCompacta ? Icons.view_list : Icons.view_compact),
            onPressed: () => setState(() => _vistaCompacta = !_vistaCompacta),
            tooltip: _vistaCompacta ? 'Vista detallada' : 'Vista compacta',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con estadísticas
          _buildHeader(),

          // Lista de registros
          Expanded(child: _buildHistorialList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToTop,
        backgroundColor: Colors.teal[800],
        child: const Icon(Icons.keyboard_arrow_up),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _getHistorialStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: 100,
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final stats = _calculateStats(docs);

          return Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total', '${docs.length}', Icons.analytics),
                _buildStatCard('CO2', '${stats['co2']}', Icons.cloud),
                _buildStatCard(
                    'Sonido', '${stats['sonido']}', Icons.graphic_eq),
                _buildStatCard('Otros', '${stats['otros']}', Icons.sensors),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getHistorialStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando historial...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "📭 No hay registros disponibles",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  "Los datos aparecerán aquí cuando estén disponibles",
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final groupedDocs = _groupByDate(docs);

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: groupedDocs.length,
            itemBuilder: (context, index) {
              final date = groupedDocs.keys.elementAt(index);
              final dayDocs = groupedDocs[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header de fecha
                  _buildDateHeader(date, dayDocs.length),
                  const SizedBox(height: 8),

                  // Registros del día
                  ...dayDocs.map(
                    (doc) => _vistaCompacta
                        ? _buildCompactCard(doc)
                        : _buildDetailedCard(doc),
                  ),

                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(String date, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 16, color: Colors.teal[700]),
          const SizedBox(width: 8),
          Text(
            date,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal[700],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.teal[700],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final tipo = (data['tipo'] ?? 'desconocido').toString();
    final valor = data['valor']?.toString() ?? 'N/D';
    final timestamp = data['timestamp'];
    final fecha = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();

    final config = _getTypeConfig(tipo);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [config['color'], config['color'].withOpacity(0.1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: config['color'].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(config['icon'], color: config['color'], size: 24),
          ),
          title: Row(
            children: [
              Text(
                tipo.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: config['color'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  valor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm:ss').format(fecha),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    config['unit'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final tipo = (data['tipo'] ?? 'desconocido').toString();
    final valor = data['valor']?.toString() ?? 'N/D';
    final timestamp = data['timestamp'];
    final fecha = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();

    final config = _getTypeConfig(tipo);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(config['icon'], color: config['color'], size: 20),
        title: Row(
          children: [
            Text(
              tipo.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            Text(
              valor,
              style: TextStyle(
                color: config['color'],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Text(
          DateFormat('HH:mm').format(fecha),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeConfig(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'co2':
        return {'icon': Icons.cloud, 'color': Colors.green[600], 'unit': 'ppm'};
      case 'sonido':
        return {
          'icon': Icons.graphic_eq,
          'color': Colors.blue[600],
          'unit': 'dB',
        };
      case 'temperatura':
        return {
          'icon': Icons.thermostat,
          'color': Colors.orange[600],
          'unit': '°C',
        };
      case 'humedad':
        return {
          'icon': Icons.water_drop,
          'color': Colors.cyan[600],
          'unit': '%',
        };
      default:
        return {'icon': Icons.sensors, 'color': Colors.grey[600], 'unit': ''};
    }
  }

  Stream<QuerySnapshot> _getHistorialStream() {
    return FirebaseFirestore.instance
        .collection('historial')
        .orderBy('timestamp', descending: true)
        .limit(500)
        .snapshots();
  }

  Map<String, List<QueryDocumentSnapshot>> _groupByDate(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'];
      final fecha =
          timestamp is Timestamp ? timestamp.toDate() : DateTime.now();

      final dateKey = DateFormat('EEEE, MMMM dd, yyyy').format(fecha);

      grouped.putIfAbsent(dateKey, () => []).add(doc);
    }

    return grouped;
  }

  Map<String, int> _calculateStats(List<QueryDocumentSnapshot> docs) {
    final stats = {'co2': 0, 'sonido': 0, 'otros': 0};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final tipo = (data['tipo'] ?? 'otros').toString().toLowerCase();

      if (stats.containsKey(tipo)) {
        stats[tipo] = stats[tipo]! + 1;
      } else {
        stats['otros'] = stats['otros']! + 1;
      }
    }

    return stats;
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}
