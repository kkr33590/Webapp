import SwiftUI
import WebKit
import AVFoundation

let startURL = URL(string: "https://movie-box.co/")!

// MARK: - Tabs

enum AppTab: CaseIterable {
    case home, movie, series, anime, top

    var title: String {
        switch self {
        case .home: return "Home"
        case .movie: return "Movies"
        case .series: return "Series"
        case .anime: return "Anime"
        case .top: return "Top"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .movie: return "film.fill"
        case .series: return "tv.fill"
        case .anime: return "sparkles"
        case .top: return "flame.fill"
        }
    }

    var path: String {
        switch self {
        case .home: return "/"
        case .movie: return "/web/movie"
        case .series: return "/web/tv-series"
        case .anime: return "/web/animated-series"
        case .top: return "/ranking-list"
        }
    }

    var url: URL { URL(string: "https://movie-box.co" + path)! }

    static func from(path raw: String) -> AppTab? {
        let p = (raw.count > 1 && raw.hasSuffix("/")) ? String(raw.dropLast()) : raw
        if p == "" || p == "/" { return .home }
        if p.hasPrefix("/web/movie") { return .movie }
        if p.hasPrefix("/web/tv-series") { return .series }
        if p.hasPrefix("/web/animated-series") { return .anime }
        if p == "/ranking-list" { return .top }
        return nil
    }
}

// MARK: - Shared state

final class AppState: ObservableObject {
    static let shared = AppState()
    @Published var immersive = false
    @Published var progress: Double = 0
    @Published var loading = true
    @Published var failed = false
    @Published var canGoBack = false
    @Published var barVisible = true
    @Published var path = "/"
    @Published var pageTitle = ""
    @Published var searching = false
    weak var web: WKWebView?

    var tab: AppTab? { AppTab.from(path: path) }

    func select(_ t: AppTab) {
        guard let w = web else { return }
        if tab == t {
            w.scrollView.setContentOffset(CGPoint(x: 0, y: -w.scrollView.contentInset.top), animated: true)
        } else {
            barVisible = true
            w.load(URLRequest(url: t.url))
        }
    }

    func setSearch(_ on: Bool) {
        searching = on
        web?.evaluateJavaScript("document.documentElement.classList.toggle('cp-showhdr', \(on))", completionHandler: nil)
        if on { web?.scrollView.setContentOffset(CGPoint(x: 0, y: -(web?.scrollView.contentInset.top ?? 0)), animated: true) }
    }
}

let bgColor = Color(red: 0.043, green: 0.059, blue: 0.090)
let bgUIColor = UIColor(red: 0.043, green: 0.059, blue: 0.090, alpha: 1)
let greenColor = Color(red: 0.18, green: 0.96, blue: 0.55)
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

func cleanTitle(_ t: String) -> String {
    t.replacingOccurrences(of: "(?i)\\s*[-|–—]\\s*moviebox.*$", with: "", options: .regularExpression)
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
        state.barVisible && !state.immersive && !state.failed
    }

    var body: some View {
        ZStack(alignment: .top) {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                if !state.immersive {
                    TopBar()
                }
                WebView(url: startURL, immersive: state.immersive)
                    .ignoresSafeArea(.container, edges: state.immersive ? Edge.Set.all : Edge.Set.bottom)
            }

            VStack {
                Spacer()
                if showBar {
                    TabBar()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 8)

            if state.failed {
                OfflineView()
            }
        }
        .statusBarHidden(state.immersive)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Shared UI pieces

struct BlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct IconButton: View {
    let icon: String
    var active: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            haptic()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(active ? greenColor : Color.white)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(PressStyle())
    }
}

struct LogoMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(accentGradient)
                .frame(width: 34, height: 34)
            Image(systemName: "play.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.black.opacity(0.8))
        }
    }
}

// MARK: - Top bar

struct TopBar: View {
    @ObservedObject var state = AppState.shared

    var showBack: Bool { state.tab == nil && state.canGoBack }

    var title: String {
        if let t = state.tab { return t == .home ? "MovieBox" : t.title }
        return state.pageTitle
    }

    var body: some View {
        HStack(spacing: 12) {
            if showBack {
                IconButton(icon: "chevron.left") { state.web?.goBack() }
            } else {
                LogoMark()
            }

            Text(title)
                .font(.system(size: state.tab == nil ? 17 : 24, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer(minLength: 8)

            IconButton(icon: "magnifyingglass", active: state.searching) {
                state.setSearch(!state.searching)
            }
            IconButton(icon: state.loading ? "xmark" : "arrow.clockwise") {
                if state.loading { state.web?.stopLoading() } else { state.web?.reload() }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(bgColor)
        .overlay(
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.white.opacity(0.06))
                    if state.loading && state.progress < 1 {
                        Rectangle()
                            .fill(accentGradient)
                            .frame(width: geo.size.width * CGFloat(state.progress))
                    }
                }
            }
            .frame(height: 2),
            alignment: .bottom
        )
    }
}

// MARK: - Bottom tab bar

struct TabBar: View {
    @ObservedObject var state = AppState.shared
    @Namespace private var ns

    func item(_ tab: AppTab) -> some View {
        let selected = state.tab == tab
        return Button(action: {
            haptic()
            state.select(tab)
        }) {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(selected ? greenColor : Color.white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if selected {
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                            .matchedGeometryEffect(id: "tabsel", in: ns)
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                item(tab)
            }
        }
        .padding(6)
        .background(BlurView())
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.45), radius: 14, x: 0, y: 6)
        .padding(.horizontal, 16)
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
        config.userContentController.add(context.coordinator, name: "cpfetch")

        config.userContentController.addUserScript(
            WKUserScript(source: cleanerJS, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        config.userContentController.addUserScript(
            WKUserScript(source: themeJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        config.userContentController.addUserScript(
            WKUserScript(source: playerJS, injectionTime: .atDocumentStart, forMainFrameOnly: false))

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
            web.observe(\.url, options: [.new]) { w, _ in
                DispatchQueue.main.async {
                    let s = AppState.shared
                    let p = w.url?.path ?? "/"
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { s.path = p }
                    if s.searching {
                        s.searching = false
                        w.evaluateJavaScript("document.documentElement.classList.remove('cp-showhdr')", completionHandler: nil)
                    }
                }
            },
            web.observe(\.title, options: [.new]) { w, _ in
                DispatchQueue.main.async { AppState.shared.pageTitle = cleanTitle(w.title ?? "") }
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
        // Leave room at the bottom so the floating tab bar never covers page content
        let bottom: CGFloat = immersive ? 0 : 88 + bottomSafeInset()
        if uiView.scrollView.contentInset.bottom != bottom {
            uiView.scrollView.contentInset.bottom = bottom
            uiView.scrollView.verticalScrollIndicatorInsets.bottom = bottom
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var observers: [NSKeyValueObservation] = []
        var lastY: CGFloat = 0

        // Hide the tab bar when scrolling down, show it when scrolling up
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
                return
            }

            // Reads HLS master playlists for the quality list (no CORS limits)
            if message.name == "cpfetch",
               let body = message.body as? [String: Any],
               let id = body["id"] as? Int,
               let s = body["url"] as? String,
               let url = URL(string: s),
               let scheme = url.scheme?.lowercased(),
               scheme == "http" || scheme == "https" {

                var req = URLRequest(url: url, timeoutInterval: 10)
                if let ref = body["referer"] as? String {
                    req.setValue(ref, forHTTPHeaderField: "Referer")
                }
                req.setValue("*/*", forHTTPHeaderField: "Accept")
                let frame = message.frameInfo
                let web = message.webView

                URLSession.shared.dataTask(with: req) { data, _, _ in
                    var text = ""
                    if let d = data, d.count < 1_500_000,
                       let t = String(data: d, encoding: .utf8),
                       t.hasPrefix("#EXTM3U") {
                        text = t
                    }
                    let arr = (try? JSONSerialization.data(withJSONObject: [text], options: []))
                        .flatMap { String(data: $0, encoding: .utf8) } ?? "[\"\"]"
                    let js = "window.__cpFetchDone(\(id), \(arr)[0]);"
                    DispatchQueue.main.async {
                        web?.evaluateJavaScript(js, in: frame, in: .page) { _ in }
                    }
                }.resume()
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
            }
        }
    }
}
