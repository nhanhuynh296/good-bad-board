import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  ColorScheme get colorScheme => theme.colorScheme;

  ResponsiveBreakpointsData get breakpoint => ResponsiveBreakpoints.of(this);
}
