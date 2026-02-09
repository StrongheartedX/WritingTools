import SwiftUI

class ResponseWindow: NSWindow {
  private var hostingController: NSHostingController<ResponseView>?

  /// Shared autosave name so all response windows restore the same size/position.
  private static let sharedAutosaveName = "ResponseWindow"

  init(
    title: String,
    content: String,
    selectedText: String,
    option: WritingOption? = nil,
    provider: any AIProvider
  ) {
    let controller = NSHostingController(
      rootView: ResponseView(
        content: content,
        selectedText: selectedText,
        option: option,
        provider: provider
      )
    )
    self.hostingController = controller

    super.init(
      contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )

    self.title = title
    self.minSize = NSSize(width: 400, height: 300)
    self.isReleasedWhenClosed = false

    self.contentViewController = controller
    configureFrameRestoration()
  }

  /// Streaming initializer: opens immediately and streams the AI response inside the window.
  init(
    title: String,
    selectedText: String,
    option: WritingOption? = nil,
    provider: any AIProvider,
    systemPrompt: String,
    userPrompt: String,
    images: [Data]
  ) {
    let controller = NSHostingController(
      rootView: ResponseView(
        selectedText: selectedText,
        option: option,
        provider: provider,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        images: images
      )
    )
    self.hostingController = controller

    super.init(
      contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )

    self.title = title
    self.minSize = NSSize(width: 400, height: 300)
    self.isReleasedWhenClosed = false

    self.contentViewController = controller
    configureFrameRestoration()
  }

  private func configureFrameRestoration() {
    // Try to restore the last-used window size/position.
    // Use a unique autosave name per window instance so multiple windows
    // don't conflict. Fall back to the shared saved frame for initial sizing.
    let uniqueName = "\(Self.sharedAutosaveName)-\(UUID().uuidString)"
    if self.setFrameAutosaveName(uniqueName) {
      // New unique name accepted — restore from the shared frame data
      self.setFrameUsingName(Self.sharedAutosaveName)
    }
    // Save the current frame under the shared name so the next window inherits it
    self.saveFrame(usingName: Self.sharedAutosaveName)

    // Only center if there was no saved frame to restore
    if UserDefaults.standard.string(forKey: "NSWindow Frame \(Self.sharedAutosaveName)") == nil {
      self.center()
    }
  }

  override func close() {
    // Persist this window's frame under the shared name so the next
    // response window opens at the same size/position.
    self.saveFrame(usingName: Self.sharedAutosaveName)
    WindowManager.shared.removeResponseWindow(self)
    super.close()
  }
}
