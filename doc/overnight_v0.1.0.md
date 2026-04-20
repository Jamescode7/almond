# Overnight 자율 실행 지시서 — JamesViewer v0.1.0 MVP

> 작성일: 2026-04-20
> 실행 브랜치: `feat/v0.1.0-mvp` (Task 0 에서 `main` 에서 분기)
> 실행자: Claude Code 자율 모드 (사용자 취침 중)
> 기준 상태: 사실상 빈 repo — `doc/` (스펙 2개 + 이 지시서) 외 코드 없음, `main` 브랜치, clean working tree
> 단일 권위 문서: `doc/app_005_md_viewer.md` (제품 스펙)

---

## 0. 실행 순서 및 정지 규칙

### 순서
1. **Task 0** — 프리플라이트 (툴체인·외부 자산·브랜치 준비)
2. **Task 1** — Xcode 프로젝트 스캐폴드 + SPM 의존성 + 마크다운 렌더 파이프라인 (pure-Swift 로직 + 최소 SwiftUI shell)
3. **Task 2** — 파일 오픈 4 경로 + 문서 윈도우 + 최근 파일 + FSEvents 자동 리로드
4. **Task 3** — UI 크롬 (타이틀바·줌·다크 모드·상태바·환경설정·단축키·본문 검색)
5. **Task 4** — Release 빌드 스크립트 + Unsigned DMG 패키징 + README 정비

### Cascade 정지 규칙
- Task 0 실패 시 **모든 Task 진행 금지** (프리플라이트)
- Task N 실패 시 **Task N+1 이후 전부 진행 금지**
- 각 Task 완료 후 **체크포인트 커밋** + `doc/RUN_REPORT.md` 누적 업데이트

### 공통 정지 조건 (어느 Task 중이든)
- `xcodebuild -scheme JamesViewer build` 실패
- `swift test` 실패 (Task 1 이후 테스트 타깃 존재)
- 동일 에러 **3회 복구 시도 실패**
- **30분 이상** 동일 이슈 교착
- 스펙(§1~§13) 에 없는 기능 추가 유혹 → 구현하지 말고 `RUN_REPORT.md` 에 "확인 필요" 로만 기록
- 스펙 §11 "네거티브 규칙" 에 해당하는 기능 시도 → 즉시 중단
- 전체 완료 시 **즉시 정지**. 시간 남아도 추가 작업 금지.

### 공통 금지 사항
- `doc/app_005_md_viewer.md`, `doc/overnight_instructions.md`, `doc/overnight_v0.1.0.md` **수정 금지** (참고만)
- 스펙 §11 전부: 편집 기능, KaTeX, Mermaid, TOC 자동 생성, PDF/HTML export, iCloud 동기화, Sparkle 자동 업데이트, 다중 탭, 결제, 애널리틱스, Windows/Linux 지원 — 구현 금지
- 외부 네트워크 호출: **다음 2 건 예외 외 전부 금지**
  - (a) SPM 의존성 resolve (Apple `swift-markdown`)
  - (b) Task 1.2 에 명시된 **pinned CDN URL 5 건** (github-markdown-css v5.5.1 라이트/다크 + highlight.js v11.9.0 번들 1 + 스타일 2)
- 새 Homebrew 패키지 설치 금지. `xcodegen`, `create-dmg` 없으면 Task 0 에서 정지하고 사용자에게 설치 요청.
- Apple Developer 계정 / 코드 서명 / notarization 관련 설정·코드·entitlement 일체 금지 (v2 로드맵)
- 네트워크 권한 entitlement (`com.apple.security.network.client`) 추가 금지. WKWebView 의 이미지 URL 로딩은 ATS 설정만으로 허용.
- `main` 브랜치 force push / reset 금지
- `.git/` 직접 편집 금지
- Destructive git 명령 (`reset --hard`, `clean -fdx`, `branch -D`, `checkout -- .`) 금지. 잘못된 커밋은 `git revert` 로만.
- `rm -rf ~/Library/Developer/Xcode/DerivedData/` 금지 (다른 프로젝트 영향). 로컬 `./build/` 제거는 허용.
- 프로덕션 배포 (GitHub Releases 태그 / 업로드) 금지. DMG 산출까지만.
- `requirements.txt`, Python 관련 파일 신규 생성 금지 (이 repo 는 Swift 전용)

### 커밋 규율
- 각 체크포인트마다 커밋 1 개
- 메시지는 **한국어 + `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`** 포함
- 메시지 본문에 `[Task N - 단계명]` + 검증 결과 한 줄 요약 (`build OK`, `swift test 5/5`) 기입
- `.xcodeproj` 는 XcodeGen 생성물이므로 `.gitignore`. 원본 `project.yml` 만 커밋.
- `vendor/` 및 `Resources/css/*.css`, `Resources/js/*.js` 는 **커밋**함 (의도된 vendored asset)

### 보고 (`doc/RUN_REPORT.md`)
- Task 0 시작 시 신규 생성
- 각 Task 완료 시 다음 포맷 누적:
  ```
  ## Task N — <제목>
  - 완료 시각: YYYY-MM-DD HH:MM (KST)
  - 커밋 범위: <start_hash>..<end_hash> (N 개 커밋)
  - 추가된 파일: ...
  - 변경된 파일: ...
  - 검증 결과: xcodebuild / swift test / plutil 결과
  - 건너뛴 항목 / 확인 필요 사항: ...
  - 다음 Task 진입 여부: yes / no (+ 사유)
  ```

---

## Task 0 — 프리플라이트 (사전 환경 확인)

### 목적
자율 모드 시작 전 툴체인·자산·브랜치 상태 확인. 하나라도 미충족 시 즉시 정지.

### 확인 항목
| # | 항목 | 검사 방법 | 실패 시 |
|---|---|---|---|
| 1 | Xcode / xcodebuild | `xcodebuild -version` → `Xcode 15.` 이상 | 정지, 사용자에게 Xcode 업데이트 요청 |
| 2 | Swift 컴파일러 | `swift --version` → `5.9` 이상 | 정지 |
| 3 | XcodeGen | `command -v xcodegen` | 정지, 사용자에게 `brew install xcodegen` 요청 |
| 4 | create-dmg | `command -v create-dmg` | **정지하지 않음.** Task 4 의 DMG 단계만 스킵 예정으로 `RUN_REPORT.md` 에 기록 |
| 5 | Git 상태 | `git status` — working tree clean, untracked 는 `doc/` 만 허용 | 정지 |
| 6 | 작업 브랜치 | `git switch -c feat/v0.1.0-mvp`  (이미 있으면 `git switch feat/v0.1.0-mvp`) | 생성 실패 시 정지 |

### 체크포인트
1. **[commit]** `doc/RUN_REPORT.md` 신규 생성, "Task 0 완료" 섹션 + 툴체인 버전·create-dmg 유무 기록.
2. 브랜치만 전환된 상태 (코드 변경 0). 커밋 메시지: `chore: Task 0 프리플라이트 완료 + RUN_REPORT 시작`

### 완료 기준
- `feat/v0.1.0-mvp` 브랜치로 체크아웃
- xcodebuild / swift / xcodegen 전부 존재
- `doc/RUN_REPORT.md` 에 Task 0 섹션 + create-dmg 상태 명시

### 정지 조건
- 필수 툴 (Xcode, swift, xcodegen) 하나라도 없음
- `main` 에 uncommitted 변경 존재

---

## Task 1 — Xcode 프로젝트 스캐폴드 + 마크다운 렌더 파이프라인

### 1.1 최종 디렉토리 구조

```
jamesviewer/
├── .gitignore
├── README.md                      # stub — Task 4 에서 재작성
├── project.yml                    # XcodeGen 스펙 (단일 권위)
├── Package.swift                  # 핵심 로직 라이브러리 + 테스트 타깃
├── Sources/
│   ├── JamesViewerCore/           # pure-Swift (Foundation 만 의존) — 테스트 대상
│   │   ├── MarkdownRenderer.swift
│   │   ├── HTMLTemplate.swift
│   │   └── FrontMatterStripper.swift
│   └── JamesViewerApp/            # SwiftUI macOS 앱 타깃
│       ├── JamesViewerApp.swift   # @main + DocumentGroup
│       ├── MarkdownDocument.swift # FileDocument (read-only)
│       ├── ContentView.swift
│       ├── MarkdownWebView.swift  # NSViewRepresentable<WKWebView>
│       ├── Info.plist
│       └── JamesViewer.entitlements
├── Tests/
│   └── JamesViewerCoreTests/
│       ├── MarkdownRendererTests.swift
│       ├── HTMLTemplateTests.swift
│       └── FrontMatterStripperTests.swift
├── Resources/
│   ├── css/
│   │   ├── github-markdown-light.css
│   │   ├── github-markdown-dark.css
│   │   ├── highlight-github.css
│   │   └── highlight-atom-one-dark.css
│   ├── js/
│   │   └── highlight.min.js
│   ├── mdv                        # 셸 스크립트 (Task 2 에서 내용 추가, Task 1 에서는 빈 파일만 예약)
│   ├── LICENSES.txt               # vendored asset 출처 + 라이선스
│   └── fixtures/
│       └── smoke.md               # 테스트용 fixture (모든 GFM 블록 포함)
└── doc/                           # (기존, 수정 금지)
```

`.gitignore` 핵심:
```
.DS_Store
build/
dist/
.swiftpm/
*.xcodeproj
```

### 1.2 Vendor 자산 다운로드 (Task 1 초반 1회만, 이후 절대 재다운로드 금지)

**허용된 URL 5 개만** 사용. 다른 URL 확장 금지. 전부 `curl -fsSL` 로, 실패 시 Task 1 정지.

```bash
mkdir -p Resources/css Resources/js vendor

# github-markdown-css v5.5.1 (MIT)
curl -fsSL -o Resources/css/github-markdown-light.css \
  https://cdn.jsdelivr.net/npm/github-markdown-css@5.5.1/github-markdown-light.css
curl -fsSL -o Resources/css/github-markdown-dark.css \
  https://cdn.jsdelivr.net/npm/github-markdown-css@5.5.1/github-markdown-dark.css

# highlight.js v11.9.0 (BSD-3-Clause)
curl -fsSL -o Resources/js/highlight.min.js \
  https://cdn.jsdelivr.net/npm/@highlightjs/cdn-assets@11.9.0/highlight.min.js
curl -fsSL -o Resources/css/highlight-github.css \
  https://cdn.jsdelivr.net/npm/@highlightjs/cdn-assets@11.9.0/styles/github.min.css
curl -fsSL -o Resources/css/highlight-atom-one-dark.css \
  https://cdn.jsdelivr.net/npm/@highlightjs/cdn-assets@11.9.0/styles/atom-one-dark.min.css
```

**Sanity check (미달 시 정지)**:
- 각 CSS 파일 크기 > 1 KB
- `highlight.min.js` > 100 KB
- 파일이 `<!DOCTYPE html>` 로 시작하지 않음 (404 HTML 방어)

`Resources/LICENSES.txt`:
```
JamesViewer bundles the following third-party assets:

1. github-markdown-css v5.5.1 (MIT)
   https://github.com/sindresorhus/github-markdown-css

2. highlight.js v11.9.0 (BSD-3-Clause)
   https://github.com/highlightjs/highlight.js

Full license texts are included in the respective upstream repositories.
```

### 1.3 Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JamesViewerCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "JamesViewerCore", targets: ["JamesViewerCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "JamesViewerCore",
            dependencies: [.product(name: "Markdown", package: "swift-markdown")],
            path: "Sources/JamesViewerCore"
        ),
        .testTarget(
            name: "JamesViewerCoreTests",
            dependencies: ["JamesViewerCore"],
            path: "Tests/JamesViewerCoreTests"
        ),
    ]
)
```

### 1.4 project.yml (XcodeGen)

```yaml
name: JamesViewer
options:
  bundleIdPrefix: com.jamescode
  deploymentTarget:
    macOS: "13.0"
  createIntermediateGroups: true
packages:
  SwiftMarkdown:
    url: https://github.com/apple/swift-markdown.git
    from: 0.3.0
  JamesViewerCore:
    path: .
targets:
  JamesViewer:
    type: application
    platform: macOS
    sources:
      - path: Sources/JamesViewerApp
    resources:
      - path: Resources
        excludes:
          - "fixtures/**"          # 테스트 fixture 는 앱 번들에 미포함
    info:
      path: Sources/JamesViewerApp/Info.plist
      properties:
        CFBundleName: JamesViewer
        CFBundleDisplayName: JamesViewer
        CFBundleIdentifier: com.jamescode.JamesViewer
        CFBundleShortVersionString: "0.1.0"
        CFBundleVersion: "1"
        LSMinimumSystemVersion: "13.0"
        NSHumanReadableCopyright: "Copyright © 2026 James. MIT License."
        CFBundleDocumentTypes:
          - CFBundleTypeName: Markdown Document
            CFBundleTypeRole: Viewer
            LSHandlerRank: Alternate
            LSItemContentTypes:
              - net.daringfireball.markdown
              - public.markdown
        NSAppTransportSecurity:
          NSAllowsArbitraryLoadsInWebContent: true
    entitlements:
      path: Sources/JamesViewerApp/JamesViewer.entitlements
      properties:
        com.apple.security.app-sandbox: true
        com.apple.security.files.user-selected.read-only: true
        com.apple.security.files.bookmarks.app-scope: true
    dependencies:
      - package: SwiftMarkdown
        product: Markdown
      - package: JamesViewerCore
        product: JamesViewerCore
```

### 1.5 핵심 Swift 로직 (`JamesViewerCore`)

**`MarkdownRenderer.swift`**
- 입력: `String` (md 본문, frontmatter 이미 제거됨 가정)
- 출력: `String` (HTML body 조각, `<article class="markdown-body">` 래퍼 없음 — 그건 `HTMLTemplate` 책임)
- `swift-markdown` 의 `Document(parsing: ...)` + `MarkupWalker` 로 HTML 생성
- 지원 블록 (spec §3.1):
  - `Heading` → `<h1>`~`<h6>`
  - `Paragraph` → `<p>`
  - `BlockQuote` → `<blockquote>`
  - `ThematicBreak` → `<hr>`
  - `UnorderedList` / `OrderedList` (중첩 포함)
  - GFM task list item → `<li><input type="checkbox" disabled ...>`
  - `CodeBlock` → `<pre><code class="language-{lang}">` (highlight.js 가 브라우저에서 처리)
  - `Table`, `TableRow`, `TableHead` — 정렬 attribute 반영
  - `Link` → `<a href="...">`
  - `Image` → `<img src="..." alt="...">`
  - inline: `Emphasis`, `Strong`, `Strikethrough`, `InlineCode`
  - `FootnoteDefinition` / `FootnoteReference`
- HTML escape 필수 (`&`, `<`, `>`, `"`, `'`)

**`FrontMatterStripper.swift`**
- 입력: 원본 md
- 정규식/라인 파싱: `^---\n` 시작 + `^---\n` 종결을 찾아 그 사이 YAML 블록 제거
- 매칭 없으면 원본 그대로 반환
- frontmatter **렌더링 금지** (spec §3.2)

**`HTMLTemplate.swift`**
- 입력:
  - `bodyHTML: String`
  - `theme: Theme` (`.light | .dark`)
  - `zoomPercent: Int` (80…200)
  - `bundleURL: URL` (resources root — CSS/JS file:// 참조용)
- 출력: 완전한 HTML 문서 문자열
- 구성:
  ```html
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="utf-8">
      <link rel="stylesheet" href="file://.../github-markdown-{light|dark}.css">
      <link rel="stylesheet" href="file://.../highlight-{github|atom-one-dark}.css">
      <style>
        body { max-width: 760px; margin: 0 auto; padding: 16px;
               font-size: {16 * zoomPercent / 100}px; line-height: 1.6; }
        @media (max-width: 760px) { body { padding: 0 16px; } }
      </style>
    </head>
    <body class="markdown-body">
      {bodyHTML}
      <script src="file://.../highlight.min.js"></script>
      <script>hljs.highlightAll();</script>
    </body>
  </html>
  ```
- 모든 `file://` URL 은 `bundleURL.appendingPathComponent(...).absoluteString` 로 생성

### 1.6 SwiftUI 앱 minimal shell (`JamesViewerApp`)

**`JamesViewerApp.swift`**
```swift
@main
struct JamesViewerApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            ContentView(document: file.document, fileURL: file.fileURL)
        }
    }
}
```

**`MarkdownDocument.swift`**
- `struct MarkdownDocument: FileDocument` 읽기 전용
- `static var readableContentTypes: [UTType] = [.init("net.daringfireball.markdown")!, .init("public.markdown")!]`
- `static var writableContentTypes: [UTType] = []` (저장 불가)
- `init(configuration:)` — 파일 내용을 String 으로 로드
- `fileWrapper(configuration:)` — 호출되면 `throw CocoaError(.featureUnsupported)`

**`ContentView.swift`** (Task 1 에서는 최소): `MarkdownWebView(rawMarkdown: document.text)` 만 노출. 타이틀바/툴바/상태바는 Task 3.

**`MarkdownWebView.swift`**
- `NSViewRepresentable` 으로 `WKWebView` 랩핑
- `updateNSView` 에서:
  1. `FrontMatterStripper.strip(text)` → stripped
  2. `MarkdownRenderer.render(stripped)` → bodyHTML
  3. `HTMLTemplate.wrap(bodyHTML: ..., theme: .light, zoomPercent: 100, bundleURL: Bundle.main.resourceURL!)` → fullHTML
  4. `webView.loadHTMLString(fullHTML, baseURL: fileURL.deletingLastPathComponent())`

### 1.7 테스트 (최소 5 개)

`Tests/JamesViewerCoreTests/MarkdownRendererTests.swift`:
- `testH1Renders()` — `# Hello` 입력 → 출력에 `<h1>Hello</h1>` 포함
- `testCodeBlockCarriesLanguageClass()` — ` ```swift\nlet x = 1\n``` ` → `<code class="language-swift">` 포함
- `testTableRenders()` — 3x2 GFM table → `<table>`, `<thead>`, `<tbody>` 포함
- `testTaskListCheckbox()` — `- [x] done` → `<input type="checkbox" checked disabled>` 포함
- `testHTMLEscaping()` — `<script>alert(1)</script>` 인용 → 출력에 `&lt;script&gt;` 로 escape

`Tests/JamesViewerCoreTests/FrontMatterStripperTests.swift`:
- `testYamlFrontMatterRemoved()` — `---\ntitle: x\n---\n\n# H` → `# H` 만 남음
- `testNoFrontMatterPreserved()` — `# H\n` → 원본 그대로
- `testMalformedFrontMatterLeftAlone()` — `---\ntitle: x` (종결 없음) → 원본 그대로

`Tests/JamesViewerCoreTests/HTMLTemplateTests.swift`:
- `testLightThemeLinksLightCSS()` — `.light` → HTML 에 `github-markdown-light.css` 링크
- `testDarkThemeLinksDarkCSS()` — `.dark` → `github-markdown-dark.css` 링크
- `testZoomAffectsFontSize()` — `zoomPercent=150` → `font-size: 24px`

### 1.8 체크포인트 커밋 순서

1. **[commit]** `.gitignore` + `README.md` stub + 빈 디렉토리 skeleton
   - 메시지: `chore: [Task 1.1] 디렉토리 스캐폴드 생성`
2. **[commit]** Vendor 자산 curl 다운로드 (5 파일) + `Resources/LICENSES.txt`
   - 메시지: `chore: [Task 1.2] vendor assets 번들 (github-markdown-css 5.5.1, highlight.js 11.9.0)`
3. **[commit]** `Package.swift` + `JamesViewerCore` 소스 3 파일
   - 메시지: `feat: [Task 1.3] JamesViewerCore — MarkdownRenderer/HTMLTemplate/FrontMatterStripper`
4. **[commit]** 테스트 3 파일 작성 + `swift test` 통과 확인
   - 메시지: `test: [Task 1.4] JamesViewerCore 단위 테스트 (11/11 통과)`
5. **[commit]** `project.yml` + SwiftUI 앱 소스 6 파일 (`JamesViewerApp`, `MarkdownDocument`, `ContentView`, `MarkdownWebView`, `Info.plist`, `.entitlements`)
   - 메시지: `feat: [Task 1.5] SwiftUI 앱 shell + XcodeGen project.yml`
6. **[verify]** `xcodegen generate` → `.xcodeproj` 생성 (커밋 제외, .gitignore 대상)
7. **[verify]** `xcodebuild -scheme JamesViewer -configuration Debug build` → `BUILD SUCCEEDED`
8. **[verify]** `swift test` → 전부 pass
9. `RUN_REPORT.md` 에 Task 1 섹션 기입

### 1.9 완료 기준
- `swift test` 통과 (11/11 또는 그 이상)
- `xcodebuild build` 성공 — DerivedData 경로에 `JamesViewer.app` 생성
- `plutil -p <.app>/Contents/Info.plist` 에 `CFBundleDocumentTypes` 포함
- `find <.app>/Contents/Resources -name "*.css"` 으로 CSS 4 개, `*.js` 로 1 개 확인
- Task 1 커밋 5 개가 `feat/v0.1.0-mvp` 에 linear 히스토리로 쌓임

### 1.10 실패 시
- Task 2/3/4 진입 금지
- `RUN_REPORT.md` 에 실패 단계 + 에러 메시지 + 복구 시도 횟수 기록

---

## Task 2 — 파일 오픈 4 경로 + 문서 윈도우 + 최근 파일 + FSEvents 자동 리로드

전제: Task 1 완료 — 앱이 md 파일을 열어 정적 렌더까지 가능.

### 2.1 구현 범위 (spec §5)

| 항목 | 구현 방식 |
|---|---|
| Finder "Open With" (§5.1 a) | Task 1.4 `CFBundleDocumentTypes` 로 이미 등록. 추가 코드 없음, **검증만**. |
| 드래그 드롭 (§5.1 b) | `ContentView` 에 `.onDrop(of: [.fileURL], isTargeted: nil) { providers in ... }`. 새 윈도우 open 은 `NSDocumentController.shared.openDocument(withContentsOf:display:completionHandler:)` |
| CMD+O 다이어로그 (§5.1 c) | `DocumentGroup` 이 자동 제공 |
| CLI `mdv` (§5.1 d) | `Resources/mdv` 셸 스크립트 (`open -a JamesViewer "$@"`) 번들링. 실제 `/usr/local/bin/mdv` 심볼릭 링크 생성은 Task 3 환경설정 UI 에서 |
| 최근 파일 (§5.3) | `DocumentGroup` + `NSDocumentController` 자동. "Clear Menu" 는 기본 제공 |
| FSEvents 리로드 (§5.4) | `DispatchSourceFileSystemObject` 래퍼 — `.write | .delete | .rename` 감지 |
| 스크롤 위치 유지 | 리로드 직전 `webView.evaluateJavaScript("window.scrollY")` → 로드 완료 후 복원 |
| 삭제/이동 배너 (§5.4) | `ContentView` 에 `@State var fileMissing: Bool`, overlay banner + "Reopen" 버튼 |
| 이미지 경로 해결 (§5.5) | `loadHTMLString(_, baseURL: fileURL.deletingLastPathComponent())` — Task 1.6 에서 이미 설정 |

### 2.2 신규 파일
- `Sources/JamesViewerApp/FileWatcher.swift` — `DispatchSourceFileSystemObject` wrapper
- `Sources/JamesViewerApp/MissingFileBanner.swift` — SwiftUI overlay view
- `Resources/mdv` — 셸 스크립트 (내용: `#!/usr/bin/env bash\nopen -a JamesViewer "$@"`)
- `Tests/JamesViewerCoreTests/FileWatcherTests.swift` — (가능하면. Foundation 기반이면 Core 로 추출, 아니면 App 타깃이라 unit test skip 하고 smoke test only)

### 2.3 `FileWatcher` 설계 (App 타깃)

```swift
final class FileWatcher {
    enum Event { case modified, deleted, renamed }
    init(url: URL, onEvent: @escaping (Event) -> Void)
    func stop()
}
```
- `open(fd, O_EVTONLY)` + `DispatchSource.makeFileSystemObjectSource(fileDescriptor:eventMask:queue:)`
- Mask: `[.write, .delete, .rename, .extend]`
- deinit 에서 close(fd) + source.cancel()

### 2.4 체크포인트 커밋 순서

1. **[commit]** `FileWatcher.swift` 추가 + `ContentView` 통합 (파일 변경 시 `document.text` 재로드 → `MarkdownWebView` 자동 갱신)
   - 메시지: `feat: [Task 2.1] FSEvents 기반 FileWatcher — 외부 수정 자동 리로드`
2. **[commit]** 스크롤 위치 보존 (WKWebView 전후 evaluateJavaScript)
   - 메시지: `feat: [Task 2.2] 리로드 시 스크롤 위치 유지`
3. **[commit]** `MissingFileBanner` + 삭제/이동 이벤트 처리
   - 메시지: `feat: [Task 2.3] 파일 삭제/이동 감지 배너`
4. **[commit]** 드래그-드롭 핸들러 (`onDrop`)
   - 메시지: `feat: [Task 2.4] 윈도우 드래그-드롭으로 md 파일 오픈`
5. **[commit]** `Resources/mdv` 셸 스크립트 추가 + `chmod +x` (git 에 executable mode 반영: `git update-index --chmod=+x Resources/mdv`)
   - 메시지: `feat: [Task 2.5] mdv CLI 엔트리 셸 스크립트 번들`
6. **[verify]** `xcodebuild build` 성공
7. **[verify]** `.app/Contents/Resources/mdv` 에 executable bit (`test -x` pass)
8. **[verify]** `plutil -p .app/Contents/Info.plist | grep -i CFBundleDocumentTypes` 출력 확인
9. `RUN_REPORT.md` Task 2 섹션 기입

### 2.5 완료 기준
- `xcodebuild build` 성공
- `JamesViewer.app/Contents/Resources/mdv` 실행 권한 포함 번들
- `Info.plist` 에 document types 2 개 (`net.daringfireball.markdown`, `public.markdown`)
- 신규 Swift 파일 전부 `project.yml` 의 sources 에 포함 (xcodegen 재실행으로 확인)

### 2.6 실패 시
Task 3/4 진입 금지. `RUN_REPORT.md` 에 기록.

---

## Task 3 — UI 크롬 (타이틀바·줌·다크·상태바·환경설정·단축키·검색)

전제: Task 2 완료 — 앱이 파일을 열고, 외부 수정 자동 리로드, 드래그-드롭 동작.

### 3.1 구현 범위 (spec §4, §6, §7)

#### 3.1.1 툴바 (spec §6)
- `.toolbar { ToolbarItemGroup(placement: .automatic) { ... } }`
- 우측 아이템: appearance 토글 (🌙/☀️), 줌 `−`, 줌 `+`
- `.windowToolbarStyle(.unified)` 적용

#### 3.1.2 줌 (spec §4.5)
- **윈도우별 state** — `@StateObject var zoom = ZoomController(defaultPercent: ...)` 또는 `@State var zoomPercent: Int = 100`
- 앱 종료 시 기본값 리셋 (persistence 없음. 환경설정의 default zoom 만 `@AppStorage`)
- 80…200 range, 10% step, clamp
- 적용: `webView.pageZoom = Double(zoomPercent) / 100.0`
- 단축키: `⌘+`, `⌘-`, `⌘0`
- SwiftUI: `Button("").keyboardShortcut("+", modifiers: .command)` 등

#### 3.1.3 다크 모드 (spec §4.4)
- 기본: 시스템 appearance 추종 (NSApp.effectiveAppearance 감지)
- `⇧⌘D`: **윈도우별 3-way toggle** (system → light → dark → system)
- override 상태 변화 시 HTML 재로드 (light/dark CSS 스왑) — `HTMLTemplate.wrap(... theme: ...)` 재호출

#### 3.1.4 상태바 (spec §6)
- `ContentView` 하단 `HStack`
- `TextStats` (spec 에 없지만 필요한 보조 타입): word count / char count / scroll %
- `JamesViewerCore/TextStats.swift` 신규:
  - `static func wordCount(_ text: String) -> Int` — `\s+` 로 split
  - `static func charCount(_ text: String) -> Int` — `text.count`
- scroll % 는 WKWebView 에서 200ms 주기 polling (Combine Timer publisher)
- 테스트: `TextStatsTests` — 영문/한글/혼합, 공백-only, 빈 문자열 케이스

#### 3.1.5 환경설정 (spec §7)
- `Settings { SettingsView() }` scene 추가
- 3 항목만:
  - **Default appearance** — Picker (`System / Light / Dark`), `@AppStorage("defaultAppearance")`
  - **Default zoom** — Picker (80/90/100/110/120/150/200), `@AppStorage("defaultZoom")`
  - **mdv CLI** — "Install symlink" / "Remove symlink" 버튼
    - 대상 경로: `/usr/local/bin/mdv` → `<Bundle>/Contents/Resources/mdv`
    - `/usr/local/bin` 쓰기 권한 없으면 실패. 실패 시 alert: "Terminal 에서 수동 설치: `sudo ln -sf <경로> /usr/local/bin/mdv`" 안내 + 경로를 클립보드에 복사

#### 3.1.6 키보드 단축키 (spec §7 전부)
| Shortcut | 구현 |
|---|---|
| `⌘O`, `⌘W`, `⌘Q` | `DocumentGroup` / 시스템 기본 |
| `⌘,` | `Settings` scene 자동 |
| `⌘+` / `⌘-` / `⌘0` | Toolbar 버튼 `.keyboardShortcut` |
| `⌘R` | `.keyboardShortcut("r", modifiers: .command)` → `document.reload()` |
| `⇧⌘D` | `.keyboardShortcut("d", modifiers: [.shift, .command])` → appearance 3-way toggle |
| `⌘F` | 검색바 toggle |
| `ESC` | 검색바 dismiss |

#### 3.1.7 본문 내 검색 (spec §7)
- `⌘F` → `SearchBar` overlay 표시 (`@State var showSearch: Bool`)
- macOS 13 호환: JavaScript `window.find(query, caseSensitive, backwards, wrap, wholeWord, searchInFrames, showDialog)` 호출
- ESC: `showSearch = false`
- morning 에 UX 세부(다음/이전 이동, 하이라이트) 수동 검증. 자율 모드에서는 "find 1회 호출 + ESC 닫기" 만 확실히 동작하면 완료.

### 3.2 신규·수정 파일
- **신규**: `Sources/JamesViewerCore/TextStats.swift`, `Tests/JamesViewerCoreTests/TextStatsTests.swift`
- **신규**: `Sources/JamesViewerApp/SettingsView.swift`, `Sources/JamesViewerApp/AppearanceMode.swift` (enum), `Sources/JamesViewerApp/SearchBar.swift`, `Sources/JamesViewerApp/CLIInstaller.swift`
- **수정**: `JamesViewerApp.swift` (Settings scene 추가), `ContentView.swift` (toolbar/상태바/검색바), `MarkdownWebView.swift` (pageZoom, JS find, scroll %), `project.yml` (신규 파일이 자동 포함되지만 xcodegen regenerate 후 확인)

### 3.3 체크포인트 커밋 순서

1. **[commit]** `TextStats.swift` + 테스트 (영문/한글/혼합/빈 문자열)
   - 메시지: `feat: [Task 3.1] TextStats — word/char count 유틸 + 테스트`
2. **[commit]** Toolbar 아이템 (appearance, 줌) + 상태바 HStack
   - 메시지: `feat: [Task 3.2] 툴바 + 하단 상태바 스캐폴드`
3. **[commit]** 줌 state + `WKWebView.pageZoom` 연동 + `⌘±0` 단축키
   - 메시지: `feat: [Task 3.3] 윈도우별 줌 컨트롤 (80-200%, 10% step)`
4. **[commit]** `AppearanceMode` enum + 3-way override + `⇧⌘D` + HTML 재로드 (light/dark CSS 스왑)
   - 메시지: `feat: [Task 3.4] 다크 모드 3-way toggle + CSS 재로드`
5. **[commit]** `SettingsView` + `@AppStorage` 3 항목 + `Settings` scene 등록
   - 메시지: `feat: [Task 3.5] 환경설정 윈도우 — appearance/zoom/mdv`
6. **[commit]** `CLIInstaller` — `/usr/local/bin/mdv` symlink install/remove + 권한 실패 alert
   - 메시지: `feat: [Task 3.6] mdv CLI symlink 설치/제거 액션`
7. **[commit]** `SearchBar` overlay + WKWebView JS find + ESC dismiss
   - 메시지: `feat: [Task 3.7] 본문 내 검색 (⌘F/ESC)`
8. **[commit]** 스크롤 % 라이브 업데이트 (200ms Timer)
   - 메시지: `feat: [Task 3.8] 상태바 스크롤 위치 실시간 표시`
9. **[verify]** `swift test` 전부 pass (Task 1 + 3.1 TextStats)
10. **[verify]** `xcodebuild build` 성공
11. `RUN_REPORT.md` Task 3 섹션 기입 + **자율 검증 불가 항목 명시**

### 3.4 완료 기준
- `swift test` 통과 (TextStats 포함 14+ 케이스)
- `xcodebuild build` 성공
- 신규 Swift 파일 전부 앱 번들에 포함 (`nm <.app>/Contents/MacOS/JamesViewer | grep -c JamesViewer` 로 symbol 증가 확인은 선택)

### 3.5 자율 모드에서 **검증 불가** → morning 수동 검증 대상
`RUN_REPORT.md` Task 3 섹션 하단에 체크리스트로 명시:
- [ ] 샘플 md 열어서 실제 렌더 품질 (heading/list/code/table/image/link 전부)
- [ ] `⌘+` / `⌘-` / `⌘0` 줌 동작 + 10% step
- [ ] `⇧⌘D` 다크 토글 → CSS 시각 변화
- [ ] 툴바 appearance/줌 아이콘 클릭
- [ ] 상태바 word/char/scroll% 갱신
- [ ] `⌘,` 환경설정 → 3 항목 UI
- [ ] mdv symlink 설치 버튼 → 터미널에서 `mdv sample.md` 동작
- [ ] `⌘F` 검색 열기 / ESC 닫기 / 매치 하이라이트
- [ ] `⌘R` 수동 리로드
- [ ] Finder 우클릭 Open With → JamesViewer 노출
- [ ] 윈도우에 md 파일 드래그드롭 → 새 윈도우 오픈
- [ ] 외부 에디터에서 md 수정 → 자동 리로드 + 스크롤 위치 유지
- [ ] 파일 삭제 → 배너 표시

### 3.6 실패 시
Task 4 진입 금지.

---

## Task 4 — Release 빌드 스크립트 + Unsigned DMG + README

전제: Task 3 완료 — 앱의 기능이 전부 완성.

### 4.1 구현 범위

#### 4.1.1 `scripts/build-release.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

xcodegen generate

xcodebuild \
  -scheme JamesViewer \
  -configuration Release \
  -derivedDataPath ./build \
  -destination 'generic/platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  clean build

APP_PATH="build/Build/Products/Release/JamesViewer.app"
test -d "$APP_PATH" || { echo "build 실패: $APP_PATH 없음"; exit 1; }
echo "빌드 완료: $APP_PATH"
```
- `chmod +x scripts/build-release.sh`

#### 4.1.2 `scripts/make-dmg.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

command -v create-dmg >/dev/null || { echo "create-dmg 미설치. skip."; exit 2; }

APP_PATH="build/Build/Products/Release/JamesViewer.app"
test -d "$APP_PATH" || { echo "먼저 build-release.sh 실행"; exit 1; }

VERSION=$(plutil -extract CFBundleShortVersionString raw "$APP_PATH/Contents/Info.plist")
mkdir -p dist
rm -f "dist/JamesViewer-${VERSION}.dmg"

STAGING=$(mktemp -d)
cp -R "$APP_PATH" "$STAGING/"
cp "scripts/dmg-contents/How to open.txt" "$STAGING/"

create-dmg \
  --volname "JamesViewer ${VERSION}" \
  --window-size 500 320 \
  --icon "JamesViewer.app" 120 160 \
  --app-drop-link 380 160 \
  "dist/JamesViewer-${VERSION}.dmg" \
  "$STAGING"

rm -rf "$STAGING"
echo "DMG: dist/JamesViewer-${VERSION}.dmg"
```
- Exit code 2 (create-dmg 없음) 는 정상 스킵으로 처리.

#### 4.1.3 `scripts/dmg-contents/How to open.txt`
```
JamesViewer 를 처음 실행하면 "확인되지 않은 개발자" 경고가 뜹니다.

1. JamesViewer.app 을 Applications 폴더로 드래그하세요.
2. Finder 에서 JamesViewer.app 을 **우클릭 > Open** 을 선택하세요.
3. 대화상자에서 **"Open"** 을 선택하세요.
4. 이후부터는 더블클릭으로 바로 실행됩니다.

이 경고는 앱이 Apple Developer 계정으로 서명되지 않았기 때문에 표시됩니다.
v2 에서 서명·notarization 이 도입되면 이 절차는 불필요해집니다.
```

#### 4.1.4 README.md 재작성
섹션:
- 프로젝트 한 줄 피치 (spec §1)
- Features (spec §3.1 발췌)
- Not included in v0.1.0 (spec §11 발췌)
- Download & install (GitHub Releases placeholder + Gatekeeper 우회 3 단계)
- Build from source (`./scripts/build-release.sh && ./scripts/make-dmg.sh`)
- Requirements (macOS 13+, Xcode 15+, XcodeGen)
- Third-party assets (github-markdown-css MIT, highlight.js BSD-3-Clause)
- License: MIT
- Roadmap → `doc/app_005_md_viewer.md` §13 로 링크

### 4.2 체크포인트 커밋 순서

1. **[commit]** `scripts/build-release.sh` + 실행 권한
   - 메시지: `build: [Task 4.1] Release 빌드 스크립트`
2. **[commit]** `scripts/make-dmg.sh` + `scripts/dmg-contents/How to open.txt`
   - 메시지: `build: [Task 4.2] unsigned DMG 패키징 스크립트`
3. **[commit]** `README.md` 전면 재작성
   - 메시지: `docs: [Task 4.3] README — 다운로드/빌드/Gatekeeper 우회 안내`
4. **[verify]** `./scripts/build-release.sh` → `build/Build/Products/Release/JamesViewer.app` 생성
5. **[verify]** `create-dmg` 존재 시 `./scripts/make-dmg.sh` → `dist/JamesViewer-0.1.0.dmg` 생성 (≥ 1 MB)
   - 부재 시: 스크립트가 exit 2 로 graceful skip 하는지 확인, `RUN_REPORT.md` 에 "DMG 단계 skip (create-dmg 미설치)" 기록
6. `RUN_REPORT.md` Task 4 섹션 기입
7. `RUN_REPORT.md` 마지막에 **"모든 Task 완료, 추가 작업 없이 정지합니다."** 명시 + **즉시 정지**

### 4.3 완료 기준
- Release 빌드 산출물 `JamesViewer.app` 생성
- (create-dmg 있을 시) DMG 파일 ≥ 1 MB 산출
- README.md 업데이트 완료
- `git status` clean
- `feat/v0.1.0-mvp` 브랜치 커밋 히스토리 정돈 (Task 별 그룹)

### 4.4 부분 실패 허용 범위
- README 까지 완료했으나 빌드 스크립트 실패: `RUN_REPORT.md` 에 기록 + Task 4 부분완료 표시 + 정지 (git revert 금지).
- DMG 단계만 실패 (build 는 성공): 정상 완료로 처리. morning 에 사용자가 수동으로 `create-dmg` 설치 후 재실행.

---

## 보조 지침

### 자율 모드 검증 한계
자율 모드에서는 CLI 레벨까지만 검증:
- `xcodebuild -scheme JamesViewer build`
- `swift test`
- `plutil -p <.app>/Contents/Info.plist`
- `find <.app>/Contents/Resources` 로 번들 자산 확인
- `test -x` / `file` / 파일 크기 sanity check

앱 실행·렌더·단축키·드래그드롭 등 **인터랙티브 검증은 전부 morning 수동**. `RUN_REPORT.md` Task 3.5 체크리스트가 morning 가이드.

### 막힐 때 판단 기준
- 스펙 `doc/app_005_md_viewer.md` 에 있는 결정 → 그대로 따름
- 스펙에 없는 결정 → **최소 구현** 선택. 기능 추가 금지.
- swift-markdown API 가 예상과 다름 → 실제 API 에 맞춰 조정, `RUN_REPORT.md` 에 "spec 과 차이" 로 기록
- SwiftUI API 가 macOS 13 에서 제한적 → 기본 동작으로 degrade, v2 로 이관 기록
- 판단 모호 → 기본값으로 진행 + `RUN_REPORT.md` 에 "확인 필요" 기록
- 치명적 오류 → 정지. destructive recovery (파일 삭제, reset --hard, branch -D) 절대 금지.

### 반복 금지 패턴
- 동일 테스트 3 번 연속 실패 → 구현 근본 재검토 or Task 정지
- `xcodebuild` 캐시 꼬임 의심 시 `rm -rf ./build/` 는 허용. `~/Library/Developer/Xcode/DerivedData/` 삭제는 금지.
- xcodegen 재생성은 필요 시 무제한 허용 (`.xcodeproj` 는 생성물).

### 참조해야 할 문서
- `doc/app_005_md_viewer.md` — 제품 단일 권위 문서 (읽기 전용)
- `doc/overnight_v0.1.0.md` — 이 파일 (읽기 전용)
- `doc/overnight_instructions.md` — 별도 프로젝트 (james-lab) 용, **무시**
- swift-markdown 공식 문서: `https://github.com/apple/swift-markdown` (SPM 으로 소스가 이미 내려옴. 추가 fetch 불필요)

### 최종 성공 시나리오
1. `doc/RUN_REPORT.md` 에 Task 0~4 섹션 전부 기입
2. 마지막 줄: **"모든 Task 완료, 추가 작업 없이 정지합니다."**
3. `feat/v0.1.0-mvp` 브랜치에 Task별 그룹핑된 커밋 히스토리 (~20 커밋 내외)
4. `git status` clean (untracked 파일 없음, staged 변경 없음)
5. `build/Build/Products/Release/JamesViewer.app` 존재, (선택) `dist/JamesViewer-0.1.0.dmg` 존재
6. morning 에 `git log --oneline` + `doc/RUN_REPORT.md` 만 읽어도 어디까지 됐고 무엇을 수동 검증할지 파악 가능

---

*끝. 위 지시 외 행동 금지. 완료 즉시 정지.*
