import SwiftUI
import WebKit

@main
struct WebAppMain: App {
    var body: some Scene {
        WindowGroup {
            WebView(url: URL(string: "https://movie-box.co/")!)
                .ignoresSafeArea()
        }
    }
}

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

    // 1. Ad network domains
    for d in adDomains {
        rules.append([
            "trigger": ["url-filter": NSRegularExpression.escapedPattern(for: d)],
            "action": ["type": "block"]
        ])
    }

    // 2. Ad URL keywords
    for k in adKeywordPatterns {
        rules.append([
            "trigger": ["url-filter": NSRegularExpression.escapedPattern(for: k)],
            "action": ["type": "block"]
        ])
    }

    // 3. Strict: block ALL third-party scripts and iframes except allowed hosts
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

    // 4. Hide ad elements with CSS
    rules.append([
        "trigger": ["url-filter": ".*"],
        "action": ["type": "css-display-none",
                   "selector": hideSelectors.joined(separator: ", ")]
    ])

    let data = try! JSONSerialization.data(withJSONObject: rules)
    return String(data: data, encoding: .utf8)!
}

// Injected into every page and frame
let cleanerJS = """
(function() {
  window.open = function() { return null; };

  var allowed = [\(allowedHostsJS)];

  function okHost(h) {
    h = (h || '').toLowerCase();
    return allowed.some(function(a) { return h === a || h.endsWith('.' + a); });
  }

  function clean() {
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
    document.querySelectorAll('div,a').forEach(function(e) {
      var s = getComputedStyle(e);
      if ((s.position === 'fixed' || s.position === 'absolute') &&
          parseInt(s.zIndex || 0) > 9999 &&
          e.offsetWidth >= innerWidth * 0.9 && e.offsetHeight >= innerHeight * 0.9 &&
          parseFloat(s.opacity) < 0.1 && !e.querySelector('video,img')) {
        e.remove();
      }
    });
  }

  new MutationObserver(clean).observe(document.documentElement, { childList: true, subtree: true });
  document.addEventListener('DOMContentLoaded', clean);
  setInterval(clean, 1500);
})();
"""

struct WebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        config.userContentController.addUserScript(
            WKUserScript(source: cleanerJS, injectionTime: .atDocumentStart, forMainFrameOnly: false))

        let web = WKWebView(frame: .zero, configuration: config)
        web.allowsBackForwardNavigationGestures = true
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "adblock-v2", encodedContentRuleList: buildRules()
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

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
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
    }
}
