import Foundation

/// The test seam that wraps `NSBundleResourceRequest`, so the ODR provider can be exercised in unit
/// tests with NO live network and no real On-Demand-Resources download.
///
/// The protocol declares only the minimal surface the ODR provider needs to trigger and observe an
/// On-Demand-Resources download:
/// - ``loadingProgress`` — the fractional (0...1) download progress to surface to the picker.
/// - ``observeProgress(_:)`` — forward fractional progress updates as the download advances, so the
///   provider can publish intermediate `downloading(progress:)` states (mirrors KVO on
///   `NSBundleResourceRequest.progress.fractionCompleted`).
/// - ``conditionallyBeginAccessingResources(completionHandler:)`` — an already-present check that
///   completes synchronously-ish with `true` when the tagged resources are already on device.
/// - ``beginAccessingResources(completionHandler:)`` — kick off the download, completing with `nil`
///   on success or an `Error` on failure.
/// - ``endAccessingResources()`` — release the request once the pack is no longer needed, so the OS
///   can purge the on-demand resources.
///
/// There is deliberately NO network/crypto/hash/signature surface here: ODR integrity is inherited
/// from App Store code-signing. This seam only triggers and observes the download.
protocol ResourceRequesting: AnyObject {
    /// The fractional download progress in `0...1`. Mirrors `NSBundleResourceRequest.progress`'s
    /// `fractionCompleted`, exposed directly so the ODR provider need not retain a `Progress` KVO.
    var loadingProgress: Double { get }

    /// Start observing fractional download progress, invoking `handler` (off the main thread, as ODR's
    /// KVO fires) with each `0...1` value as the download advances. The receiver retains the
    /// observation for its lifetime; ``endAccessingResources()`` tears it down.
    func observeProgress(_ handler: @escaping (Double) -> Void)

    /// Ask whether the tagged resources are already present on device WITHOUT triggering a download.
    /// Completes with `true` when present (the request is then already accessing them).
    func conditionallyBeginAccessingResources(completionHandler: @escaping (Bool) -> Void)

    /// Begin accessing (downloading if necessary) the tagged resources. Completes with `nil` on
    /// success or the underlying `Error` on failure. The receiver must be retained for the lifetime
    /// of the access; call ``endAccessingResources()`` when finished.
    func beginAccessingResources(completionHandler: @escaping (Error?) -> Void)

    /// Release access to the tagged resources, letting the OS purge them when appropriate.
    func endAccessingResources()
}

/// Factory that produces a ``ResourceRequesting`` for a set of ODR tags. Production wires
/// ``LiveResourceRequest``; tests inject a fake that drives progress and completion by hand.
typealias ResourceRequestFactory = (_ tags: Set<String>) -> ResourceRequesting

/// The production ``ResourceRequesting`` conformer, owning a real `NSBundleResourceRequest`.
///
/// It forwards `loadingProgress` from the request's `progress.fractionCompleted` and bridges the
/// request's completion-handler API onto the seam. No integrity checks are performed here — ODR
/// content authenticity is guaranteed by App Store code-signing.
final class LiveResourceRequest: ResourceRequesting {
    private let request: NSBundleResourceRequest

    /// Retained KVO observation of `progress.fractionCompleted`; released on ``endAccessingResources()``.
    private var progressObservation: NSKeyValueObservation?

    init(tags: Set<String>, bundle: Bundle = .main) {
        request = NSBundleResourceRequest(tags: tags, bundle: bundle)
    }

    var loadingProgress: Double {
        request.progress.fractionCompleted
    }

    func observeProgress(_ handler: @escaping (Double) -> Void) {
        progressObservation = request.progress.observe(
            \.fractionCompleted,
            options: [.initial, .new]
        ) { progress, _ in
            handler(progress.fractionCompleted)
        }
    }

    func conditionallyBeginAccessingResources(completionHandler: @escaping (Bool) -> Void) {
        request.conditionallyBeginAccessingResources(completionHandler: completionHandler)
    }

    func beginAccessingResources(completionHandler: @escaping (Error?) -> Void) {
        request.beginAccessingResources(completionHandler: completionHandler)
    }

    func endAccessingResources() {
        progressObservation?.invalidate()
        progressObservation = nil
        request.endAccessingResources()
    }

    /// The production factory: wires a ``LiveResourceRequest`` over the main bundle for a tag set.
    static let factory: ResourceRequestFactory = { tags in
        LiveResourceRequest(tags: tags)
    }
}
