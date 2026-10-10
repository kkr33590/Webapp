import SwiftUI
import WebKit
import AVFoundation

let startURL = URL(string: "https://movie-box.co/")!

// MARK: - Shared state

final class AppState: ObservableObject {
    static let shared = AppState()
    @Published var immersive = false
    @Published var progress: Double = 0
    @Published var loading = true
    @Published var failed = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isHome = true
    @Published var barVisible = true
    @Published var splash = true
    weak var web: WKWebView?

    let launch = Date()
    private var splashScheduled = false

    func dismissSplash() {
        guard splash, !splashScheduled else { return }
        splashScheduled = true
        let wait = max(0, 1.8 - Date().timeIntervalSince(launch))
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
            withAnimation(.easeInOut(duration: 0.5)) { self.splash = false }
        }
    }
}

let bgColor = Color(red: 0.067, green: 0.086, blue: 0.122)
let bgUIColor = UIColor(red: 0.067, green: 0.086, blue: 0.122, alpha: 1)
let accentGradient = LinearGradient(
    colors: [Color(red: 0.11, green: 0.72, blue: 1.0), Color(red: 0.18, green: 0.96, blue: 0.55)],
    startPoint: .leading, endPoint: .trailing)

func haptic() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
}

func bottomSafeInset() -> CGFloat {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: { $0.isKeyWindow })?.safeAreaInsets.bottom ?? 0
}

// MARK: - Orientation control

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationMask: UIInterfaceOrientationMask = .allButUpsideDown

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        return true
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationMask
    }
}

func setMask(_ mask: UIInterfaceOrientationMask, force: Bool) {
    AppDelegate.orientationMask = mask
    if #available(iOS 16.0, *) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first else { return }
        scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        if force {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in }
        }
    } else {
        if force {
            let o: UIInterfaceOrientation = (mask == .landscape) ? .landscapeRight : .portrait
            UIDevice.current.setValue(o.rawValue, forKey: "orientation")
        }
        UIViewController.attemptRotationToDeviceOrientation()
    }
}

func applyOrientation(_ mode: String) {
    DispatchQueue.main.async {
        AppState.shared.immersive = (mode == "landscape")
    }
    switch mode {
    case "landscape":
        setMask(.landscape, force: true)
    case "portrait":
        setMask(.portrait, force: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            setMask(.allButUpsideDown, force: false)
        }
    default:
        setMask(.allButUpsideDown, force: false)
    }
}

// MARK: - App

@main
struct WebAppMain: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup { RootView() }
    }
}

struct RootView: View {
    @ObservedObject var state = AppState.shared

    var showBar: Bool {
        state.barVisible && !state.immersive && !state.failed && !state.splash
    }

    var body: some View {
        ZStack(alignment: .top) {
            bgColor.ignoresSafeArea()

            WebView(url: startURL, immersive: state.immersive)
                .ignoresSafeArea(.container, edges: state.immersive ? Edge.Set.all : Edge.Set.bottom)

            if state.loading && state.progress < 1 && !state.splash {
                GeometryReader { geo in
                    Rectangle()
                        .fill(accentGradient)
                        .frame(width: geo.size.width * CGFloat(state.progress), height: 3)
                }
                .frame(height: 3)
                .allowsHitTesting(false)
            }

            VStack {
                Spacer()
                if showBar {
                    NavBar()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 8)

            if state.failed {
                OfflineView()
            }

            if state.splash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .statusBarHidden(state.immersive)
        .preferredColorScheme(.dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                AppState.shared.dismissSplash()
            }
        }
    }
}

// MARK: - Splash (app open loading screen)

struct SplashView: View {
    @ObservedObject var state = AppState.shared
    @State private var pulse = false

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(accentGradient)
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(red: 0.11, green: 0.72, blue: 1.0).opacity(0.5), radius: 24)
                    Image(systemName: "play.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.8))
                }
                .scaleEffect(pulse ? 1.06 : 0.94)

                Text("MovieBox")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Movies & TV shows")
                    .font(.footnote)
                    .foregroundColor(.gray)

                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12)).frame(width: 180, height: 4)
                    Capsule().fill(accentGradient)
                        .frame(width: 180 * CGFloat(max(0.08, state.progress)), height: 4)
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Bottom navigation bar

struct BlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct NavButton: View {
    let icon: String
    var enabled: Bool = true
    var highlight: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard enabled else { return }
            haptic()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(enabled ? (highlight ? Color(red: 0.18, green: 0.96, blue: 0.55) : .white)
                                         : Color.white.opacity(0.28))
                .frame(width: 58, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
    }
}

struct NavBar: View {
    @ObservedObject var state = AppState.shared

    func goHome() {
        guard let w = state.web else { return }
        if state.isHome {
            w.scrollView.setContentOffset(CGPoint(x: 0, y: -w.scrollView.contentInset.top), animated: true)
        } else {
            w.load(URLRequest(url: startURL))
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            NavButton(icon: "chevron.left", enabled: state.canGoBack) { state.web?.goBack() }
            NavButton(icon: "chevron.right", enabled: state.canGoForward) { state.web?.goForward() }
            NavButton(icon: "house.fill", highlight: state.isHome) { goHome() }
            NavButton(icon: state.loading ? "xmark" : "arrow.clockwise") {
                if state.loading { state.web?.stopLoading() } else { state.web?.reload() }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(BlurView())
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.45), radius: 14, x: 0, y: 6)
    }
}

// MARK: - Offline screen

struct OfflineView: View {
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 46))
                    .foregroundColor(Color.white.opacity(0.85))
                Text("No connection")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Check your internet and try again")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Button(action: {
                    haptic()
                    let s = AppState.shared
                    s.failed = false
                    s.loading = true
                    if let w = s.web {
                        if w.url == nil { w.load(URLRequest(url: startURL)) } else { w.reload() }
                    }
                }) {
                    Text("Try again")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(accentGradient)
                        .cornerRadius(24)
                }
                .padding(.top, 6)
            }
        }
    }
}

// MARK: - Ad blocking config

// Set to false if video or pages break
let strictMode = true

let allowedHosts = ["movie-box.co", "moviebox.ph", "moviebox.co", "aoneroom.com"]

let allowedHostsJS = allowedHosts.map { "\"\($0)\"" }.joined(separator: ",")

let adDomains = [
    "doubleclick.net", "googlesyndication.com", "googleadservices.com",
    "adservice.google.com", "google-analytics.com", "googletagmanager.com",
    "googletagservices.com", "pagead2.googlesyndication.com",
    "adsterra.com", "adsterratools.com", "highperformanceformat.com",
    "profitablecpmrate.com", "effectivegatecpm.com", "highcpmgate.com",
    "popads.net", "popcash.net", "propellerads.com", "propellerclick.com",
    "exoclick.com", "exosrv.com", "exdynsrv.com", "juicyads.com",
    "trafficjunky.net", "clickadu.com", "hilltopads.net", "adcash.com",
    "onclickads.net", "onclkds.com", "outbrain.com", "taboola.com",
    "mgid.com", "revcontent.com", "adnxs.com", "criteo.com", "criteo.net",
    "pubmatic.com", "rubiconproject.com", "openx.net", "smartadserver.com",
    "an.yandex.ru", "mc.yandex.ru", "unityads.unity3d.com", "applovin.com",
    "mopub.com", "inmobi.com", "adsco.re", "a-ads.com", "ad-maven.com",
    "admaven.com", "monetag.com", "richpartners.com", "tsyndicate.com",
    "trafficstars.com", "bidvertiser.com", "yllix.com",
    "adskeeper.com", "adspyglass.com", "ero-advertising.com",
    "facebook.net", "hotjar.com", "clarity.ms", "scorecardresearch.com",
    "amazon-adsystem.com", "moatads.com", "adsafeprotected.com",
    "popmyads.com", "pushwhy.com", "notifpush.com", "pushnami.com",
    "kdmbhsvl.com", "tzegilo.com", "acscdn.com", "histats.com"
]

let adKeywordPatterns = [
    "popunder", "pop-under", "adserver", "/ads/", "/adv/", "banner-ad",
    "/prebid", "/pagead/", "/adsbygoogle"
]

let hideSelectors = [
    "ins.adsbygoogle", "[id^='google_ads']", "[id*='ad-container']",
    "[class*='ad-banner']", "[class*='adsbox']", "[class*='ad-slot']",
    "[class*='popup-ad']", "[id*='popunder']", "[class*='sponsor']",
    "iframe[src*='ads']", "iframe[src*='banner']",
    "a[href*='utm_source=movieboxco']", "a[href*='utm_source=MB_ID']",
    "a[href*='theapkbox.com']"
]

func buildRules() -> String {
    var rules: [[String: Any]] = []

    for d in adDomains {
        rules.append([
            "trigger": ["url-filter": NSRegularExpression.escapedPattern(for: d)],
            "action": ["type": "block"]
        ])
    }

    for k in adKeywordPatterns {
        rules.append([
            "trigger": ["url-filter": NSRegularExpression.escapedPattern(for: k)],
            "action": ["type": "block"]
        ])
    }

    if strictMode {
        rules.append([
            "trigger": [
                "url-filter": ".*",
                "resource-type": ["script", "document"],
                "load-type": ["third-party"],
                "unless-domain": allowedHosts.map { "*" + $0 }
            ],
            "action": ["type": "block"]
        ])
    }

    rules.append([
        "trigger": ["url-filter": ".*"],
        "action": ["type": "css-display-none",
                   "selector": hideSelectors.joined(separator: ", ")]
    ])

    let data = try! JSONSerialization.data(withJSONObject: rules)
    return String(data: data, encoding: .utf8)!
}

let cleanerJS = """
(function() {
  window.open = function() { return null; };

  var allowed = [\(allowedHostsJS)];
  var timer = null;

  function okHost(h) {
    h = (h || '').toLowerCase();
    return allowed.some(function(a) { return h === a || h.endsWith('.' + a); });
  }

  function clean() {
    timer = null;
    document.querySelectorAll('iframe').forEach(function(f) {
      try {
        var u = new URL(f.src, location.href);
        if (f.src && !okHost(u.hostname)) f.remove();
      } catch (e) {}
    });
    document.querySelectorAll('ins.adsbygoogle, [id^="google_ads"]').forEach(function(e) { e.remove(); });
    document.querySelectorAll('a[target="_blank"]').forEach(function(a) {
      try {
        var u = new URL(a.href, location.href);
        if (!okHost(u.hostname)) a.remove();
      } catch (e) {}
    });
    try {
      var pts = [[innerWidth / 2, innerHeight / 2], [innerWidth / 2, innerHeight * 0.3], [innerWidth / 2, innerHeight * 0.7]];
      pts.forEach(function(p) {
        document.elementsFromPoint(p[0], p[1]).forEach(function(e) {
          if (e === document.documentElement || e === document.body || e.tagName === 'VIDEO') return;
          if (e.closest && e.closest('.cp-root')) return;
          var s = getComputedStyle(e);
          if ((s.position === 'fixed' || s.position === 'absolute') &&
              parseInt(s.zIndex || 0) > 9999 &&
              e.offsetWidth >= innerWidth * 0.9 && e.offsetHeight >= innerHeight * 0.9 &&
              parseFloat(s.opacity) < 0.1 && !e.querySelector('video,img')) {
            e.remove();
          }
        });
      });
    } catch (e) {}
  }

  function schedule() { if (!timer) timer = setTimeout(clean, 400); }

  new MutationObserver(function(muts) {
    for (var i = 0; i < muts.length; i++) {
      var t = muts[i].target;
      if (t && t.nodeType !== 1) t = t.parentElement;
      if (t && t.closest && t.closest('.cp-root')) continue;
      schedule();
      return;
    }
  }).observe(document.documentElement, { childList: true, subtree: true });

  document.addEventListener('DOMContentLoaded', schedule);
  setInterval(clean, 3000);
})();
"""

// MARK: - Web view

struct WebView: UIViewRepresentable {
    let url: URL
    let immersive: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        config.userContentController.add(context.coordinator, name: "orient")

        config.userContentController.addUserScript(
            WKUserScript(source: cleanerJS, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        config.userContentController.addUserScript(
            WKUserScript(source: themeJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        config.userContentController.addUserScript(
            WKUserScript(source: playerJS, injectionTime: .atDocumentEnd, forMainFrameOnly: false))

        let web = WKWebView(frame: .zero, configuration: config)
        web.allowsBackForwardNavigationGestures = true
        web.allowsLinkPreview = false
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator

        web.isOpaque = false
        web.backgroundColor = bgUIColor
        web.scrollView.backgroundColor = bgUIColor

        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.showsVerticalScrollIndicator = false
        web.scrollView.showsHorizontalScrollIndicator = false
        web.scrollView.minimumZoomScale = 1
        web.scrollView.maximumZoomScale = 1
        web.scrollView.bounces = true

        let rc = UIRefreshControl()
        rc.tintColor = .white
        rc.addTarget(context.coordinator, action: #selector(Coordinator.refresh(_:)), for: .valueChanged)
        web.scrollView.refreshControl = rc

        // Observers: progress, back/forward state, home state, scroll direction
        let c = context.coordinator
        c.observers = [
            web.observe(\.estimatedProgress, options: [.new]) { w, _ in
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.2)) { AppState.shared.progress = w.estimatedProgress }
                }
            },
            web.observe(\.canGoBack, options: [.new]) { w, _ in
                DispatchQueue.main.async { AppState.shared.canGoBack = w.canGoBack }
            },
            web.observe(\.canGoForward, options: [.new]) { w, _ in
                DispatchQueue.main.async { AppState.shared.canGoForward = w.canGoForward }
            },
            web.observe(\.url, options: [.new]) { w, _ in
                DispatchQueue.main.async {
                    let u = w.url
                    let host = u?.host?.lowercased() ?? ""
                    let path = u?.path ?? ""
                    AppState.shared.isHome = allowedHosts.contains(where: { host == $0 || host.hasSuffix("." + $0) })
                        && (path == "" || path == "/")
                }
            },
            web.scrollView.observe(\.contentOffset, options: [.new]) { [weak c] sv, _ in
                c?.scrolled(sv.contentOffset.y)
            }
        ]

        AppState.shared.web = web
        AppState.shared.loading = true

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "adblock-v5", encodedContentRuleList: buildRules()
        ) { list, error in
            DispatchQueue.main.async {
                if let list = list {
                    web.configuration.userContentController.add(list)
                }
                web.load(URLRequest(url: url))
            }
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Leave room at the bottom so the floating bar never covers page content
        let bottom: CGFloat = immersive ? 0 : 80 + bottomSafeInset()
        if uiView.scrollView.contentInset.bottom != bottom {
            uiView.scrollView.contentInset.bottom = bottom
            uiView.scrollView.verticalScrollIndicatorInsets.bottom = bottom
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var observers: [NSKeyValueObservation] = []
        var lastY: CGFloat = 0

        // Hide the bar when scrolling down, show it when scrolling up
        func scrolled(_ y: CGFloat) {
            let d = y - lastY
            var target: Bool? = nil
            if y < 40 { target = true }
            else if d > 12 { target = false }
            else if d < -12 { target = true }
            if abs(d) > 12 || y < 40 { lastY = y }
            if let t = target, AppState.shared.barVisible != t {
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        AppState.shared.barVisible = t
                    }
                }
            }
        }

        @objc func refresh(_ rc: UIRefreshControl) {
            if AppState.shared.immersive { rc.endRefreshing(); return }
            AppState.shared.web?.reload()
        }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            if message.name == "orient", let mode = message.body as? String {
                applyOrientation(mode)
            }
        }

        func isAllowed(_ url: URL?) -> Bool {
            guard let url = url, let scheme = url.scheme?.lowercased() else { return true }
            if ["about", "blob", "data"].contains(scheme) { return true }
            guard scheme == "http" || scheme == "https" else { return false }
            guard let host = url.host?.lowercased() else { return false }
            return allowedHosts.contains { host == $0 || host.hasSuffix("." + $0) }
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let isMain = navigationAction.targetFrame?.isMainFrame ?? true
            if isMain && !isAllowed(navigationAction.request.url) {
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if isAllowed(navigationAction.request.url) {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            AppState.shared.loading = true
            AppState.shared.failed = false
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                AppState.shared.barVisible = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            AppState.shared.loading = false
            webView.scrollView.refreshControl?.endRefreshing()
            AppState.shared.dismissSplash()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handle(error, webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handle(error, webView)
        }

        func handle(_ error: Error, _ webView: WKWebView) {
            AppState.shared.loading = false
            webView.scrollView.refreshControl?.endRefreshing()
            let code = (error as NSError).code
            let netCodes = [NSURLErrorNotConnectedToInternet, NSURLErrorTimedOut,
                            NSURLErrorNetworkConnectionLost, NSURLErrorCannotFindHost,
                            NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed]
            if netCodes.contains(code) {
                AppState.shared.failed = true
                AppState.shared.dismissSplash()
            }
        }
    }
}
