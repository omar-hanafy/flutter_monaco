/// @docImport 'package:flutter_monaco/src/widgets/monaco_focus_guard.dart';
library;

import 'package:flutter/widgets.dart';

/// A specialized [RouteObserver] for applications using Monaco Editor.
///
/// This observer helps [MonacoFocusGuard] track route changes more effectively.
/// While a standard `RouteObserver<PageRoute>` works, this one is typed for
/// [ModalRoute] to support more types of transitions (like dialogs) that
/// might require editor focus/interaction management.
class MonacoRouteObserver extends RouteObserver<ModalRoute<dynamic>> {}
