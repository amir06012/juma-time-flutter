import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pendingJummahTimesTitle)),
      body: StreamBuilder(
        stream: firestoreService.watchPendingSubmissions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text(l10n.noPendingSubmissions));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] as String? ?? doc.id,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.time1Label(data['pendingJummahTime1'] ?? '-')),
                      if (data['pendingJummahTime2'] != null)
                        Text(l10n.time2Label(data['pendingJummahTime2'])),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => firestoreService.approvePending(doc.id),
                            child: Text(l10n.approveAction),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => firestoreService.rejectPending(doc.id),
                            child: Text(l10n.rejectAction),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
