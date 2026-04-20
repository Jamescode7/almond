# JamesViewer v0.1.0 — 야간 자율 실행 리포트

> 실행 브랜치: `feat/v0.1.0-mvp`
> 실행자: Claude Code (Opus 4.7, 1M context)
> 지시서: `doc/overnight_v0.1.0.md`
> 스펙: `doc/app_005_md_viewer.md`

---

## Task 0 — 프리플라이트

- **완료 시각**: 2026-04-20 (세션 시작)
- **커밋 범위**: `2da54fa..HEAD` (초기 커밋 + Task 0)
- **툴체인**:
  - Xcode 26.3 ✓
  - Swift 6.2.4 ✓
  - xcodegen `/opt/homebrew/bin/xcodegen` ✓
  - create-dmg `/opt/homebrew/bin/create-dmg` ✓
- **브랜치**: `main` 초기 커밋 생성 → `feat/v0.1.0-mvp` 체크아웃
- **변경된 파일**: `doc/RUN_REPORT.md` 신규
- **검증 결과**: 전 필수 툴 존재. Task 1~4 전부 진행 가능.
- **다음 Task 진입 여부**: **yes** (Task 1 착수)

---

## Task 1 — Xcode 프로젝트 스캐폴드 + 마크다운 렌더 파이프라인

- **완료 시각**: 2026-04-20 22:48 (KST)
- **커밋 범위**: `b17ec9f..2a9de87` (5 개 커밋)
- **추가된 파일**:
  - `.gitignore`, `README.md` (stub)
  - `Package.swift`, `project.yml`
  - `Sources/JamesViewerCore/{MarkdownRenderer,HTMLTemplate,FrontMatterStripper}.swift`
  - `Sources/JamesViewerApp/{JamesViewerApp,MarkdownDocument,ContentView,MarkdownWebView}.swift`
  - `Tests/JamesViewerCoreTests/{MarkdownRenderer,HTMLTemplate,FrontMatterStripper}Tests.swift`
  - `Resources/css/github-markdown-{light,dark}.css` (MIT)
  - `Resources/css/highlight-{github,atom-one-dark}.css` (BSD-3)
  - `Resources/js/highlight.min.js` (BSD-3)
  - `Resources/LICENSES.txt`
- **검증 결과**:
  - `swift build`: 성공 (`JamesViewerCore` 라이브러리)
  - `swift test`: **22/22 통과**
    - MarkdownRendererTests: 11 (H1-H6, 코드블록, 테이블, 태스크리스트, HTML escape, link, image, em/strong/del, 중첩 list)
    - FrontMatterStripperTests: 5 (YAML 제거, 없음 보존, malformed 보존, `...` 종결자, `---` 수평선 오판 방지)
    - HTMLTemplateTests: 6 (light/dark CSS, zoom font-size, clamp, article 래핑, hljs 포함)
  - `xcodebuild Debug build`: **BUILD SUCCEEDED**
  - Bundle 검증: `JamesViewer.app/Contents/Resources/` 에 CSS 4 + JS 1 + LICENSES.txt 전부 포함
  - Info.plist: `CFBundleDocumentTypes`, `UTImportedTypeDeclarations`, `NSAllowsArbitraryLoadsInWebContent`, `CFBundleShortVersionString=0.1.0`, `LSMinimumSystemVersion=13.0` 확인
  - Universal binary: x86_64 + arm64
- **스펙과 차이 / 확인 필요**:
  - **Footnote 미지원**: spec §3.1 에 "각주" 포함되어 있으나 swift-markdown 0.7.3 에는 `FootnoteDefinition`/`FootnoteReference` 노드가 없음. 원문이 raw text 로 fallthrough 됨. 렌더러는 오류 없음. v2 에서 커스텀 파서 추가 검토.
  - **Info.plist / entitlements**: `xcodegen generate` 가 매번 덮어쓰므로 `.gitignore` 처리. `project.yml` 이 단일 권위.
  - **Resources 번들 구조**: XcodeGen `buildPhase: resources` 로 flat 배치되어 `Contents/Resources/` 직하 모든 파일 존재. `HTMLTemplate` 경로를 flat 에 맞춰 조정.
  - **Code signing**: `CODE_SIGN_IDENTITY=-` (ad-hoc). v2 에서 Developer 계정 서명 전환 예정.
- **자율 검증 불가 → morning 확인 대상**: 실제 앱 실행 + md 열기 + WKWebView 렌더 결과
- **다음 Task 진입 여부**: **yes** (Task 2 착수)

---

## Task 2 — 파일 오픈 + FSEvents 자동 리로드

- **완료 시각**: 2026-04-20 22:53 (KST)
- **커밋 범위**: `75f86c5..a14349d` (5 개 커밋)
- **추가된 파일**:
  - `Sources/JamesViewerApp/FileWatcher.swift` — DispatchSourceFileSystemObject 래퍼
  - `Sources/JamesViewerApp/MissingFileBanner.swift` — 삭제/이동 오버레이 배너
  - `Resources/mdv` (755) — CLI 엔트리 셸 스크립트
- **변경된 파일**:
  - `Sources/JamesViewerApp/ContentView.swift` — @State text + watcher + 드래그드롭 + 배너 통합
  - `Sources/JamesViewerApp/MarkdownWebView.swift` — Coordinator + WKNavigationDelegate + 스크롤 보존 + 중복 렌더 억제
- **검증 결과**:
  - `xcodebuild Debug build`: **BUILD SUCCEEDED**
  - `swift test`: 22/22 유지 (Task 1 순수 로직 테스트)
  - Bundle 검증: `.app/Contents/Resources/mdv` executable bit OK (`test -x` 통과)
  - Info.plist: `CFBundleDocumentTypes.LSItemContentTypes` 에 `net.daringfireball.markdown` + `public.markdown` 포함
- **구현 범위**:
  - FSEvents: `.write/.delete/.rename/.extend` 전부 감지 → `.modified` / `.deleted` / `.renamed` 이벤트로 매핑
  - 리로드: 메인 스레드 디스패치, security-scoped resource 진입·해제
  - 스크롤 보존: WKNavigationDelegate `didFinish` 에서 `window.scrollTo(0, Y)` 재적용. 첫 로드는 스킵.
  - 드래그드롭: `onDrop(of: [.fileURL])` + NSWorkspace.open → CFBundleDocumentTypes 로 자기 자신에게 라우팅
  - mdv: `exec open -a JamesViewer "$@"` — Task 3 환경설정 UI 에서 `/usr/local/bin/mdv` symlink 설치 액션 예정
- **자율 검증 불가 → morning 확인 대상**:
  - Finder 우클릭 "Open With" → JamesViewer 노출
  - 윈도우에 md 파일 드래그 → 새 윈도우 오픈
  - 외부 에디터에서 md 저장 → 자동 리로드 + 스크롤 위치 유지
  - 파일 삭제/이동 → 배너 노출 + Dismiss
  - Finder 에서 `.markdown` / `.mdown` / `.mkd` 확장자 인식
- **스펙과 차이 / 확인 필요**:
  - spec §5.3 "Open Recent 최대 10 개, Clear Menu 포함" — SwiftUI DocumentGroup 기본 동작. macOS 가 자동 관리하므로 별도 코드 없음 (morning 확인).
  - spec §5.4 "파일이 사라졌습니다 + 재오픈 버튼" — 배너에 재오픈 버튼은 생략. 재생성/복원 여부가 즉시 반영되지 않을 수 있어 Dismiss 만 제공. v2 검토.
- **다음 Task 진입 여부**: **yes** (Task 3 착수)

---

## Task 3 — UI 크롬 (툴바·줌·다크 모드·상태바·환경설정·단축키·검색)

- **완료 시각**: 2026-04-20 23:00 (KST)
- **커밋 범위**: `cffd866..c1ed327` (8 개 커밋)
- **추가된 파일**:
  - `Sources/JamesViewerCore/TextStats.swift` — word/char count
  - `Tests/JamesViewerCoreTests/TextStatsTests.swift` — 10 케이스
  - `Sources/JamesViewerApp/AppearanceMode.swift` — enum + next()
  - `Sources/JamesViewerApp/DocumentViewState.swift` — 윈도우별 상태
  - `Sources/JamesViewerApp/SettingsView.swift` — 환경설정 UI
  - `Sources/JamesViewerApp/CLIInstaller.swift` — mdv symlink 설치/제거
  - `Sources/JamesViewerApp/SearchBar.swift` — ⌘F UI
  - `Sources/JamesViewerApp/WebViewStore.swift` — webView 참조 공유
- **변경된 파일**:
  - `Sources/JamesViewerCore/HTMLTemplate.swift` — zoomPercent 파라미터 제거 (pageZoom 으로 이관)
  - `Tests/JamesViewerCoreTests/HTMLTemplateTests.swift` — zoom 관련 테스트 재정비
  - `Sources/JamesViewerApp/JamesViewerApp.swift` — Settings scene 추가
  - `Sources/JamesViewerApp/ContentView.swift` — 툴바/상태바/검색바/단축키/스크롤% 전면 통합
  - `Sources/JamesViewerApp/MarkdownWebView.swift` — pageZoom + scroll tracking + search + coordinator 확장
- **검증 결과**:
  - `swift test`: **32/32 통과** (22 → 32, TextStats 10 개 추가)
  - `xcodebuild Debug build`: **BUILD SUCCEEDED**
  - HTMLTemplate 테스트 6 개 (light/dark/article/hljs/fixedFont/darkBG)
- **구현 범위**:
  - 툴바: appearance 토글(🌗), 줌- / 줌+ 버튼 + help 툴팁
  - 줌: `webView.pageZoom`, 80-200% 10% step, ⌘= ⌘+ ⌘- ⌘0 단축키
  - 다크: 3-way (system/light/dark), ⇧⌘D, override 없을 때 NSApp.effectiveAppearance 추종
  - 상태바: word / char / scroll% (WKScriptMessageHandler 기반 실시간)
  - 환경설정: ⌘, 로 오픈, 3 항목 (Default appearance, Default zoom, mdv CLI)
  - mdv CLI: `/usr/local/bin/mdv` symlink. 샌드박스 권한 부족 시 수동 명령 클립보드 복사 + alert
  - 검색: ⌘F 오픈 / ESC 닫기, JS `window.find`, Enter 로 다음 매치 순회
  - 리로드: ⌘R → reloadFromDisk
- **자율 검증 불가 → morning 확인 대상**:
  - 줌 단축키 실제 반응 (⌘= / ⌘+ / ⌘- / ⌘0)
  - ⇧⌘D 다크 토글 시 CSS 실제 스왑 + 플래시 여부
  - 툴바 appearance/줌 버튼 시각적 렌더
  - 상태바 스크롤% 수치 업데이트 반응성
  - ⌘, 환경설정 창 UI (3 항목 레이아웃)
  - mdv 심볼릭 링크 설치 alert 흐름 (샌드박스 실패 → Terminal 안내)
  - ⌘F 검색바 표시/숨김 + TextField 포커스 + Enter 네비게이션
  - ESC 검색바 닫기 (showSearch=true 일 때만 활성)
- **스펙과 차이 / 확인 필요**:
  - spec §3.1.7 검색 "다음/이전 매치 네비게이션 (⌘G / ⇧⌘G)" — MVP 에서는 Enter 반복만 제공. ⌘G 별도 단축키 없음. v2.
  - spec §3.1.5 환경설정 default zoom — 선택지 (80/90/100/110/120/150/200) 으로 7 단계 제공. spec "환경설정(⌘,) MVP 화면은 3개 항목만" 을 그대로 유지.
- **다음 Task 진입 여부**: **yes** (Task 4 착수)

---

## Task 4 — Release 빌드 + Unsigned DMG + README

- **완료 시각**: 2026-04-20 23:08 (KST)
- **커밋 범위**: `276bd18..8a12289` (2 개 커밋)
- **추가된 파일**:
  - `scripts/build-release.sh` (755) — xcodegen + xcodebuild Release
  - `scripts/make-dmg.sh` (755) — create-dmg + --skip-jenkins
  - `scripts/dmg-contents/How to open.txt` — Gatekeeper 우회 안내 (EN)
  - `README.md` — 프로젝트 소개 + 다운로드 + 빌드 + 아키텍처 (전면 재작성)
  - `LICENSE` — MIT 전문
- **검증 결과**:
  - `./scripts/build-release.sh`: **BUILD SUCCEEDED** — universal binary (x86_64+arm64)
  - `./scripts/make-dmg.sh`: **dist/JamesViewer-0.1.0.dmg** 생성 (1,296,941 bytes ≈ 1.24 MB)
  - `hdiutil verify`: 체크섬 VALID
  - DMG 마운트 검증: `JamesViewer.app` + `Applications` symlink + `How to open.txt` 3 요소 포함
  - `swift test`: 32/32 유지
  - `git status`: clean
- **스펙과 차이 / 확인 필요**:
  - create-dmg `--skip-jenkins`: sandbox/non-GUI 환경에서 Finder AppleScript 가 timeout 되어 추가. DMG 아이콘 배치 등 Finder 미화 단계는 스킵됨. 기능상 차이 없음 (drag-drop 영역은 create-dmg 가 심볼릭 링크로 처리).
  - 코드 서명: `CODE_SIGN_IDENTITY="-"` ad-hoc 만. v2 에서 Apple Developer 서명 + notarization 전환.
- **자율 검증 불가 → morning 확인 대상**:
  - DMG 더블클릭 → 마운트 → 드래그드롭 UX
  - 첫 실행 시 Gatekeeper 경고 → 우클릭 Open 흐름
  - 설치 후 더블클릭 실행 지속성
- **다음 Task 진입 여부**: **N/A** — 전 Task 완료

---

## 모든 Task 완료, 추가 작업 없이 정지합니다.

### 요약
- 전체 커밋 수: **23 개** (`feat/v0.1.0-mvp`)
- 총 테스트: **32 / 32 통과** (JamesViewerCore 순수 Swift 테스트)
- 빌드: Debug / Release 양쪽 성공, universal binary
- DMG: `dist/JamesViewer-0.1.0.dmg` (1.24 MB) — unsigned, Gatekeeper 경고 우회 안내 동봉
- 최종 working tree: clean

### Morning 수동 검증 체크리스트 (종합)

**실행 전 준비**
- [x] `open build/Build/Products/Release/JamesViewer.app` 또는 DMG 에서 설치 후 실행
- [ ] Gatekeeper 경고 시 우클릭 > Open 으로 한 번 승인

**Task 1 렌더**
- [x] 샘플 md 파일 열기 → 헤딩/본문/리스트/표/이미지/링크/코드블록 전부 정상 렌더
- [x] 코드 블록 언어별 syntax highlighting 색 적용
- [ ] 이미지: 상대경로/절대경로/URL 모두 로드

**Task 2 파일 오픈 + 리로드**
- [ ] Finder 우클릭 "Open With" → JamesViewer 노출
- [ ] 윈도우에 md 파일 드래그드롭 → 새 윈도우 오픈
- [ ] `.markdown` / `.mdown` / `.mkd` 확장자도 인식
- [ ] 외부 에디터에서 md 저장 → 자동 리로드 + 스크롤 위치 유지
- [ ] 파일 삭제 → "File is missing" 배너 노출 + Dismiss 동작
- [ ] File > Open Recent 에 최근 열람 파일 기록

**Task 3 UI 크롬**
- [ ] ⌘+ / ⌘= / ⌘- / ⌘0 줌 동작 (80-200% 10% step)
- [ ] 툴바 줌 버튼 (−/+) 클릭 동작
- [ ] ⇧⌘D 3-way 다크 토글 — 시각적 CSS 전환 + 깜빡임 없음
- [ ] 툴바 appearance 아이콘 (🌗/☀️/🌙) 전환
- [ ] 상태바 word / char / scroll% 실시간 업데이트
- [ ] ⌘, 환경설정 창 → 3 항목 UI (Appearance / Zoom / mdv)
- [ ] Preferences 에서 Default appearance 변경 → 새 윈도우에 반영
- [ ] mdv Install 버튼 → alert (샌드박스 실패 시 Terminal 명령 클립보드 복사)
- [ ] Terminal 에서 `/usr/local/bin/mdv sample.md` 실행 → 앱에서 오픈
- [ ] ⌘R 수동 리로드
- [ ] ⌘F 검색바 노출 + TextField 자동 포커스
- [ ] 검색어 입력 → 첫 매치 하이라이트 (WKWebView 네이티브 selection)
- [ ] Enter 반복 → 다음 매치로 이동
- [ ] ESC 검색바 닫기 + 선택 해제

**Task 4 배포**
- [ ] DMG 마운트 → 드래그드롭 레이아웃 (세부 시각은 skip-jenkins 로 단순)
- [ ] JamesViewer.app → Applications 드래그
- [ ] 처음 실행 시 Gatekeeper 경고 → 우클릭 Open
- [ ] 두번째 실행은 더블클릭으로 바로 실행

### 사용자 확인 필요 (optional)
- GitHub repo URL (README 에 placeholder `seunghwasong/jamesviewer` 사용 — 실제 repo 생성 시 치환)
- 아이콘 디자인 (spec §12 — 별도 세션 대기)
- Apple Developer 계정 취득 시 v0.2.0 에서 서명 + notarization 전환

### 다음 권장 동작 (morning)
1. `doc/RUN_REPORT.md` 전체 리뷰
2. 위 체크리스트 수동 검증
3. 문제 없으면 `git merge feat/v0.1.0-mvp` → `main`
4. GitHub repo 생성 후 push → Releases 에 DMG 업로드

*— Claude Opus 4.7 (1M context), 2026-04-20 야간 자율 실행 종료*

---

## Post-handoff — 사용자 morning 검증 & 후속 수정 (2026-04-21)

야간 종료 후 morning 에 사용자가 DMG 설치 + 실사용 테스트 진행. 3 건 회귀 발견 → 동일 세션에서 추가 수정.

### 검증 결과 (사용자 보고)

| # | 항목 | 결과 |
|---|---|---|
| 1 | 앱 실행 | ✓ 정상 |
| 2 | Gatekeeper 경고 | ✗ 안 뜸 → **정상** (로컬 빌드는 `com.apple.quarantine` flag 없음, 배포 DMG 는 브라우저 다운로드 시 flag 부착돼 경고 뜸) |
| 3 | Finder 우클릭 Open With → JamesViewer | ✗ 빈 창 (텍스트 렌더 안 됨) |
| 4 | 초기 창 크기 | ✗ 최소 사이즈 (600×400) 로 열림 — Typora 수준 기대 |

### 후속 수정

#### 수정 1 — 초기 창 크기 (해결)
- **신규**: `Sources/JamesViewerApp/WindowConfigurator.swift` (NSViewRepresentable)
- 첫 렌더 시 `NSWindow` 를 960×720 센터 배치
- `setFrameAutosaveName("JamesViewerDocument")` 으로 사용자 리사이즈 → 다음 윈도우에 기억
- 식별자 기반 1 회성 실행 (loop 방지)

#### 수정 2 — Open With 빈 렌더 (해결, 3 단계 반복)

**진단 1** (`ensureContentLoaded` 추가): ContentView `onAppear` 에서 `text.isEmpty && fileURL != nil` 일 때 disk 재로드. → 효과 없음.

**진단 2** (`AppDelegate` 추가): `@NSApplicationDelegateAdaptor` + 5 중 open 경로 (application(_:open:) / openFile: / openFiles: / NSAppleEventManager 직접 등록) + NSLog 진단. → `log stream` 에 아무 출력 없음. NSLog 자체가 unified log 에 안 들어가는 상태.

**진단 3** (`DiagLog.swift`): `os.Logger` + NSLog + 앱 컨테이너 파일(`~/Library/Containers/com.jamescode.JamesViewer/Data/Documents/jamesviewer-diag.log`) 3 중 출력. → 파일 로그에서 흐름 확인:
```
AppDelegate.init
applicationWillFinishLaunching
handleAEOpenDocuments fired, items=1
AE parsed 1 url(s): ["/Users/.../epic_oidc_handoff.md"]
opening via NSDocumentController: epic_oidc_handoff.md
applicationDidFinishLaunching
MarkdownDocument.init(configuration:) text.count=5301
ContentView.init text.count=5301, fileURL=/Users/.../epic_oidc_handoff.md
MarkdownWebView.makeNSView called, markdown.count=5301
updateNSView: loading HTML (html=10133, ...)
openDocument success
```
→ `ContentView` 까지 text=5301 정상 도달. 그러나 **webView navigation delegate (didStart/didFinish/didFail) 가 일절 안 찍힘** — `loadHTMLString` 이 silently drop.

**원인 확정**: WKWebView 는 `loadHTMLString(_:baseURL:)` 에 `file://` baseURL (`~/Desktop/`) 을 주면, HTML 내부의 `<link href="file:///Applications/JamesViewer.app/Contents/Resources/*.css">` 같은 **cross-directory file:// 서브리소스 참조를 거부** 하고 전체 navigation 을 silent fail 시킴.

**해결**:
1. `HTMLTemplate.wrap`: bundleURL 의 CSS/JS 파일을 `String(contentsOf:)` 로 읽어 `<style>` / `<script>` 태그에 인라인 임베드 → file:// 외부 참조 완전 제거
2. `MarkdownWebView.updateNSView`: `loadHTMLString(html, baseURL: nil)` → baseURL 자체를 없애서 cross-directory 검사 우회
3. 부수 효과: HTML 크기 ~150 KB 로 증가 (이전 ~10 KB), 렌더 시마다 CSS/JS 재파싱. 실사용 성능 영향 무시 가능.
4. 이미지 상대경로 해석은 v2 에서 처리 필요 (baseURL=nil 이므로 현재는 이미지 로드 안 됨).

**검증**: 사용자 재테스트 → "야호 드디어 나온다" ✓

#### 수정 3 — readableContentTypes 방어
- `MarkdownDocument.readableContentTypes` 에 `.plainText` 항상 포함 → `net.daringfireball.markdown` UTI 등록 실패 케이스에서도 오픈 가능
- `init(configuration:)` non-throwing 으로 완화 → `regularFileContents` nil 이어도 빈 text 로 진행, ContentView 의 ensureContentLoaded 가 disk fallback

### 최종 상태

- **전체 커밋**: 29 개 on `feat/v0.1.0-mvp`
- **테스트**: 35/35 (JamesViewerCore 순수 로직)
- **빌드**: Debug / Release 양쪽 성공, universal binary (x86_64 + arm64)
- **DMG**: `dist/JamesViewer-0.1.0.dmg` (~1.35 MB), hdiutil verify VALID
- **진단 코드**: 완전 제거 (DiagLog.swift 삭제, 모든 NSLog/DiagLog.log 호출 제거)
- **알려진 제약** (v2):
  - 이미지 상대경로 미지원 (baseURL=nil 이라). 절대경로/URL 은 OK
  - `com.apple.security.files.bookmarks.app-scope` entitlement 는 유지되지만 현재 코드는 security-scoped 북마크 저장 안 함 (Open Recent 영속성 morning 확인 필요)
  - Footnote 미지원 (swift-markdown 0.7.3 한계)
  - ⌘G 네비게이션 미구현 (검색 Enter 반복으로 대체)

### 추가 파일
- `Sources/JamesViewerApp/AppDelegate.swift` — 5 중 open 경로 라우팅
- `Sources/JamesViewerApp/WindowConfigurator.swift` — 초기 창 크기 + autosave

*— 2026-04-21 post-handoff 세션 종료*
