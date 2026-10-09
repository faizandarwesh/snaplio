import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_lio/app/router.dart';
import 'package:snap_lio/app/shell.dart';
import 'package:snap_lio/app/theme/app_theme.dart';

/// Real ShellFrame + FloatingNavBar + AnimatedBranchContainer, placeholder tabs.
GoRouter _router() => GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute(
          builder: (c, s, shell) => ShellFrame(shell: shell),
          navigatorContainerBuilder: (c, shell, children) => AnimatedBranchContainer(currentIndex: shell.currentIndex, children: children),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (c, s) => const _HomePage())]),
            StatefulShellBranch(routes: [GoRoute(path: '/search', builder: (c, s) => const _Page('search page'))]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/spend',
                builder: (c, s) => const _Page('spend page', next: '/spend/sub'),
                routes: [GoRoute(path: 'sub', builder: (c, s) => const _Page('spend sub page'))],
              ),
            ]),
            StatefulShellBranch(routes: [GoRoute(path: '/clean', builder: (c, s) => const _Page('clean page'))]),
          ],
        ),
        GoRoute(path: '/detail', builder: (c, s) => const Scaffold(body: Center(child: Text('detail page')))),
      ],
    );

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // Like the Home Spend card: switches tab without the nav bar.
          TextButton(onPressed: () => StatefulNavigationShell.of(context).goBranch(Tabs.spend), child: const Text('open spend')),
          TextButton(onPressed: () => context.push('/detail'), child: const Text('open detail')),
          for (var i = 0; i < 60; i++) SizedBox(height: 60, child: Text('home row $i')),
        ],
      ),
    );
  }
}

/// Deliberately not scrollable: once hidden here, the nav could never return.
class _Page extends StatelessWidget {
  const _Page(this.label, {this.next});
  final String label;
  final String? next;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (next != null) TextButton(onPressed: () => context.go(next!), child: const Text('deeper')),
            ],
          ),
        ),
      );
}

Future<GoRouter> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = _router();
  await tester.pumpWidget(MaterialApp.router(theme: AppTheme.dark(), routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

bool _navShown(WidgetTester tester) {
  final slide = tester.widget<AnimatedSlide>(find.ancestor(of: find.byType(FloatingNavBar), matching: find.byType(AnimatedSlide)));
  return slide.offset == Offset.zero;
}

Future<void> _scrollHomeDown(WidgetTester tester) async {
  await tester.drag(find.text('home row 3'), const Offset(0, -500));
  await tester.pumpAndSettle();
}

Finder _visible(String text) => find.text(text).hitTestable();

void main() {
  testWidgets('each nav item opens its tab', (tester) async {
    await _pump(tester);
    expect(_visible('home row 0'), findsOneWidget);
    for (final (label, page) in [('Search', 'search page'), ('Spend', 'spend page'), ('Clean', 'clean page'), ('Home', 'home row 0')]) {
      await tester.tap(find.bySemanticsLabel(label));
      await tester.pumpAndSettle();
      expect(_visible(page), findsOneWidget, reason: label);
    }
  });

  testWidgets('nav hides on scroll down and returns on scroll up', (tester) async {
    await _pump(tester);
    await _scrollHomeDown(tester);
    expect(_navShown(tester), isFalse);
    await tester.drag(find.text('home row 10'), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(_navShown(tester), isTrue);
  });

  testWidgets('nav comes back after a programmatic tab switch', (tester) async {
    await _pump(tester);
    await tester.drag(find.text('home row 3'), const Offset(0, -40));
    await tester.pumpAndSettle();
    // Make sure the "open spend" button is still reachable while hidden.
    await tester.drag(find.text('home row 3'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(_navShown(tester), isFalse);
    // Scroll the button back into view with a programmatic jump.
    tester.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open spend'));
    await tester.pumpAndSettle();
    expect(_visible('spend page'), findsOneWidget);
    expect(_navShown(tester), isTrue, reason: 'Spend has nothing to scroll; the nav must not stay hidden');
  });

  testWidgets('nav comes back after returning from a pushed screen', (tester) async {
    final router = await _pump(tester);
    await _scrollHomeDown(tester);
    expect(_navShown(tester), isFalse);
    router.push('/detail');
    await tester.pumpAndSettle();
    expect(find.text('detail page'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(_navShown(tester), isTrue);
  });

  testWidgets('Back on another tab goes Home instead of closing the app', (tester) async {
    await _pump(tester);
    await tester.tap(find.bySemanticsLabel('Clean'));
    await tester.pumpAndSettle();
    expect(_visible('clean page'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_visible('home row 0'), findsOneWidget);
  });

  testWidgets('re-tapping the active tab returns it to its root', (tester) async {
    await _pump(tester);
    await tester.tap(find.bySemanticsLabel('Spend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('deeper'));
    await tester.pumpAndSettle();
    expect(_visible('spend sub page'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Spend'));
    await tester.pumpAndSettle();
    expect(_visible('spend page'), findsOneWidget);
  });

  testWidgets('tabs keep their state when switching', (tester) async {
    await _pump(tester);
    await _scrollHomeDown(tester);
    final offset = tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
    // Bring the nav back, switch away and back.
    await tester.drag(find.text('home row 12'), const Offset(0, 40));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pumpAndSettle();
    final after = tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
    expect(after, closeTo(offset - 40, 1));
  });
}
