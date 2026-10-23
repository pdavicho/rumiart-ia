import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/history_controller.dart';
import '../models/recognition_history.dart';
import '../widgets/states/state_widgets.dart';

/// Pantalla con 2 tabs:
///   1. Mi Historial — reconocimientos locales (Hive)
///   2. Comunidad    — reconocimientos recientes de todos (Firestore)
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HistoryController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0221),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B0E3F),
          title: const Text(
            'Historial',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // Botón limpiar historial (solo en tab 1)
            Obx(() => controller.history.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Color(0xFFFF9800)),
                    tooltip: 'Limpiar historial',
                    onPressed: () => _confirmClear(context, controller),
                  )
                : const SizedBox.shrink()),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFFFF9800),
            labelColor: Color(0xFFFF9800),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.history), text: 'Mi Historial'),
              Tab(icon: Icon(Icons.people), text: 'Comunidad'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LocalHistoryTab(controller: controller),
            const _CommunityTab(),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, HistoryController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B0E3F),
        title: const Text('Limpiar historial',
            style: TextStyle(color: Colors.white)),
        content: const Text('¿Eliminar todo el historial local?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.clearAll();
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800)),
            child: const Text('Eliminar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Historial local ────────────────────────────────────────────────────

class _LocalHistoryTab extends StatelessWidget {
  final HistoryController controller;
  const _LocalHistoryTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.history.isEmpty) {
        return const EmptyWidget(
          message: 'Aún no has reconocido ninguna obra.\nUsa la cámara para comenzar.',
          icon: Icons.history_edu,
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.history.length,
        itemBuilder: (context, i) {
          final item = controller.history[i];
          return _HistoryCard(item: item, controller: controller);
        },
      );
    });
  }
}

class _HistoryCard extends StatelessWidget {
  final RecognitionHistory item;
  final HistoryController controller;
  const _HistoryCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.key.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => controller.deleteEntry(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B0E3F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.5)),
        ),
        child: Row(
          children: [
            // Icono sala
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF4A148C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.art_track, color: Color(0xFF00E5FF), size: 22),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.artworkName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(item.sala,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    '${(item.confidence * 100).toStringAsFixed(1)}% • ${_formatTime(item.timestamp)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Botón favorito
            IconButton(
              icon: Icon(
                item.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: item.isFavorite ? const Color(0xFFFF9800) : Colors.white38,
              ),
              onPressed: () => controller.toggleFavorite(item),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} días';
  }
}

// ── Tab 2: Comunidad (Firestore) ──────────────────────────────────────────────

class _CommunityTab extends StatelessWidget {
  const _CommunityTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recognition_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Cargando reconocimientos...');
        }
        if (snapshot.hasError) {
          return const EmptyWidget(
            message: 'No se pudo cargar la comunidad.\nInicia sesión e intenta de nuevo.',
            icon: Icons.people_outline,
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyWidget(
            message: 'Aún no hay reconocimientos de la comunidad.',
            icon: Icons.people_outline,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _CommunityCard(data: data);
          },
        );
      },
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CommunityCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final email = (data['userEmail'] as String? ?? 'Usuario');
    final inicial = email.isNotEmpty ? email[0].toUpperCase() : 'U';
    final artworkName = data['artworkName'] as String? ?? 'Obra';
    final sala = data['sala'] as String? ?? '';
    final ts = data['timestamp'] as Timestamp?;
    final timeAgo = ts != null ? _formatTime(ts.toDate()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B0E3F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          // Avatar con inicial
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF4A148C),
            child: Text(inicial,
                style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artworkName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(sala,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Text(timeAgo,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} días';
  }
}
