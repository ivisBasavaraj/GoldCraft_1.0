import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inter_c/core/constants/app_constants.dart';
import 'package:inter_c/features/auth/data/auth_repository.dart';
import 'package:inter_c/features/auth/domain/auth_models.dart';
import 'package:inter_c/features/jobs/domain/job_model.dart';
import 'package:inter_c/features/jobs/data/jobs_provider.dart';
import 'package:inter_c/features/jobs/presentation/screens/job_detail_screen.dart';
import 'package:inter_c/features/jobs/presentation/screens/karagar_home_screen.dart';
import 'package:inter_c/features/jobs/presentation/widgets/karagar_job_card.dart';
import 'package:inter_c/features/material_issuance/data/issuance_provider.dart';
import 'package:inter_c/features/material_issuance/domain/issuance_model.dart';
import 'package:inter_c/features/material_receipts/data/receipts_provider.dart';

void main() {
  testWidgets('tapping a job card opens that job once', (tester) async {
    final router = await _pumpCard(tester, _job());
    addTearDown(router.dispose);

    await tester.tap(find.text('Gold Ring'));
    await tester.pumpAndSettle();

    expect(find.text('Job details: job-123'), findsOneWidget);
  });

  testWidgets('View My Work opens the job details route', (tester) async {
    final router = await _pumpCard(tester, _job());
    addTearDown(router.dispose);

    await tester.tap(find.text('VIEW MY WORK'));
    await tester.pumpAndSettle();

    expect(find.text('Job details: job-123'), findsOneWidget);
  });

  testWidgets('mouse hover and click on a job card opens details',
      (tester) async {
    final router = await _pumpCard(tester, _job());
    addTearDown(router.dispose);

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer();
    await tester.pump();
    final target = tester.getCenter(find.text('Gold Ring'));
    await pointer.moveTo(target);
    await tester.pump();
    await pointer.down(target);
    await pointer.up();
    await tester.pumpAndSettle();

    expect(find.text('Job details: job-123'), findsOneWidget);
  });

  testWidgets('mouse click on the card action opens details', (tester) async {
    final router = await _pumpCard(tester, _job());
    addTearDown(router.dispose);

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer();
    await tester.pump();
    final target = tester.getCenter(find.text('VIEW MY WORK'));
    await pointer.moveTo(target);
    await tester.pump();
    await pointer.down(target);
    await pointer.up();
    await tester.pumpAndSettle();

    expect(find.text('Job details: job-123'), findsOneWidget);
  });

  testWidgets('mouse navigation works from the full karagar home screen',
      (tester) async {
    final router = await _pumpHome(tester, _job());
    addTearDown(router.dispose);

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer();
    await tester.pump();
    final target = tester.getCenter(find.text('Gold Ring'));
    await pointer.moveTo(target);
    await tester.pump();
    await pointer.down(target);
    await pointer.up();
    await tester.pumpAndSettle();

    expect(find.text('Job details: job-123'), findsOneWidget);
  });

  testWidgets('the actual job details page builds after mouse navigation',
      (tester) async {
    final router = await _pumpHomeWithDetails(tester, _job());
    addTearDown(router.dispose);

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer();
    await tester.pump();
    final target = tester.getCenter(find.text('Gold Ring'));
    await pointer.moveTo(target);
    await tester.pump();
    await pointer.down(target);
    await pointer.up();
    await tester.pumpAndSettle();

    expect(find.text('Job Details'), findsOneWidget);
    expect(find.text('Start Work'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gold Issued keeps OCR evidence column without a scan',
      (tester) async {
    final job = _job();
    final router = await _pumpHomeWithDetails(
      tester,
      job,
      issuances: [
        MaterialIssuance(
          id: 'issuance-1',
          transactionId: 'ISS-1001',
          jobId: job.id,
          karagarId: job.karagarId,
          karagarName: job.karagarName,
          physicalWeightGrams: 10,
          reversed: false,
          createdAt: DateTime(2026, 11, 1),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.tap(find.text('Gold Ring'));
    await tester.pumpAndSettle();

    expect(find.text('OCR EVIDENCE'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('-'), matching: find.byType(Center)),
      findsOneWidget,
    );
    expect(find.text('No scan'), findsNothing);
  });

  testWidgets('a job without an ID shows an error instead of navigating',
      (tester) async {
    final router = await _pumpCard(tester, _job(id: ''));
    addTearDown(router.dispose);

    await tester.tap(find.text('Gold Ring'));
    await tester.pump();

    expect(
        find.text('Unable to open this job: missing job ID.'), findsOneWidget);
    expect(find.text('Job details: '), findsNothing);
  });
}

Future<GoRouter> _pumpCard(WidgetTester tester, Job job) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => Scaffold(
          body: ListView(children: [KaragarJobCard(job: job)]),
        ),
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (_, state) => Scaffold(
          body: Text('Job details: ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

Future<GoRouter> _pumpHome(WidgetTester tester, Job job) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const KaragarHomeScreen(),
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (_, state) => Scaffold(
          body: Text('Job details: ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myJobsProvider.overrideWith((ref) async => [job]),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<GoRouter> _pumpHomeWithDetails(
  WidgetTester tester,
  Job job, {
  List<MaterialIssuance> issuances = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    AppConstants.keyAccessToken: 'test-token',
  });
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const KaragarHomeScreen(),
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (_, state) => JobDetailScreen(
          jobId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        myJobsProvider.overrideWith((ref) async => [job]),
        myIssuancesProvider(job.id).overrideWith((ref) async => issuances),
        myReceiptsProvider(job.id).overrideWith((ref) async => []),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Job _job({String id = 'job-123'}) => Job(
      id: id,
      jobNumber: '1001',
      title: 'Gold Ring',
      requiredWeightGrams: 10,
      dueDate: DateTime(2026, 12, 1),
      status: JobStatus.assigned,
      karagarId: 'karagar-1',
      karagarName: 'Test Karagar',
      issuedWeightGrams: 10,
      returnedWeightGrams: 0,
      createdAt: DateTime(2026, 11, 1),
    );

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(Dio());

  @override
  Future<AuthUser> getMe() async => const AuthUser(
        id: 'karagar-1',
        name: 'Test Karagar',
        username: 'test',
        role: UserRole.karagar,
      );
}
