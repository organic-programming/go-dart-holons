# Xcode "Run Script" build phase — copy daemon binary into .app bundle.
#
# Add this as a build phase in your Runner target (after "Run Script:
# Flutter Build"). Adjust DAEMON_BINARY to match your project layout.
#
# The binary is placed in Contents/Resources/ and can be resolved at
# runtime with NSBundle.mainBundle.resourcePath.

DAEMON_BINARY="${SRCROOT}/../build/daemon"
DEST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/Resources/"

if [ -f "$DAEMON_BINARY" ]; then
  mkdir -p "$DEST"
  cp "$DAEMON_BINARY" "$DEST/daemon"
  chmod +x "$DEST/daemon"
  echo "Bundled daemon binary into Resources"
else
  echo "warning: daemon binary not found at $DAEMON_BINARY"
  echo "Run: ./scripts/build_daemon.sh before flutter build"
fi
