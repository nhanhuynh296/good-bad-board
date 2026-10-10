/// Design tokens for responsive breakpoints.
///
/// Reference: ARCHITECTURE.md Section 1.5
library;

/// Phone: below this width
const int phoneMaxWidth = 719;

/// Tablet: 720–1079px
const int tabletMinWidth = 720;
const int tabletMaxWidth = 1079;

/// Desktop: 1080px and above
const int desktopMinWidth = 1080;

/// Returns true if the width represents a phone layout (<720px).
bool isPhone(double width) => width < tabletMinWidth;

/// Returns true if the width represents a tablet layout (720–1079px).
bool isTablet(double width) =>
    width >= tabletMinWidth && width < desktopMinWidth;

/// Returns true if the width represents a desktop layout (≥1080px).
bool isDesktop(double width) => width >= desktopMinWidth;
