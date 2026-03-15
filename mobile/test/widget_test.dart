import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exequeue_mobile/features/queue/domain/entities/queue_stage.dart';
import 'package:exequeue_mobile/features/queue/presentation/widgets/status_pill.dart';

void main() {
  testWidgets('renders the waiting status pill', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatusPill(status: QueueStage.waiting),
          ),
        ),
      ),
    );

    expect(find.text('Waiting'), findsOneWidget);
  });
}
