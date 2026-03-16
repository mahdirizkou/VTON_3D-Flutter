import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/tripo_generation_job.dart';

class TripoResultPage extends StatelessWidget {
  const TripoResultPage({
    super.key,
    required this.job,
  });

  final TripoGenerationJob job;

  Future<void> _openResult(BuildContext context) async {
    final String? modelUrl = job.modelUrl;
    if (modelUrl == null || modelUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No model URL is available for this job.')),
      );
      return;
    }

    final Uri uri = Uri.parse(modelUrl);
    final bool opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the generated model URL.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Generated Model')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '3D generation result',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Job ID: ${job.jobId}'),
                    if ((job.taskId ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text('Task ID: ${job.taskId}'),
                    ],
                    const SizedBox(height: 6),
                    Text('Status: ${job.displayStatus}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Model URL',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(job.modelUrl ?? 'No model URL available'),
                    if ((job.errorMessage ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        job.errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openResult(context),
                        icon: const Icon(Icons.open_in_browser_outlined),
                        label: const Text('Open Result'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
