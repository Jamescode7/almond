# App 005 스펙: JamesViewer — macOS 마크다운 뷰어 (Viewer-only MVP)

> 작성일: 2026-04-20
> 상태: 제품 스펙 · 기술 스택 · 배포 · 렌더링 전략 · 이름 · 릴리스 타깃 모두 확정. 아이콘 디자인만 §12 에서 추후 세션 대기.
> 트랙: james-lab 모노레포 외부. 로컬 `application/james-viewer/` sibling 폴더 + 별도 GitHub repo.
> 배포: GitHub Releases 의 unsigned DMG (사용자 우클릭 우회 설치)
> 타깃: v0.1.0 릴리스 2026 Q2 (2026-06-30 까지)

---

## 1. 개요

- **제품명**: JamesViewer
- **한 줄 피치**: Typora 같은 WYSIWYG 스타일의 읽기 전용 마크다운 뷰어. macOS 네이티브.
- **타깃 사용자**: 개발자·작가·학생 중 "편집은 VSCode/Obsidian/Typora 같은 다른 툴에서, 읽기만 이걸로" 하고 싶은 사람
- **포지셔닝**: Typora/Marked 2/MacDown 대비 — "무료·가벼움·오픈소스·뷰어 전용"
- **판매 포인트**:
  - 유료 구독이 없다 (Typora €14.99 / Marked 2 $13.99 대체)
  - 편집 기능이 없어 UI 가 단순하고, 딱 "읽기 목적"에 최적화
  - 완전 오프라인 (네트워크 요청 0건)
  - macOS 네이티브 느낌 (Swift + SwiftUI)

---

## 2. 확정된 설계 결정

### 2.1 플랫폼

- macOS 13 Ventura 이상
- Apple Silicon + Intel 동시 지원 (universal binary)

### 2.2 기능 범위

- **읽기 전용**. 편집·저장 기능은 MVP 에서 명시적으로 제외
- 사용자는 md 파일을 "열어서 본다". 끝.

### 2.3 배포 방식

- **GitHub Releases 의 unsigned DMG**
- Apple Developer Program (연 $99) **미등록** 상태로 시작
- 사용자 첫 실행 시 Gatekeeper "확인되지 않은 개발자입니다" 경고 노출
- 해결: Finder 에서 JamesViewer.app 우클릭 > Open 클릭 → 한 번 승인 후 영구 허용
- 이 절차를 README 상단에 2~3줄 + 스크린샷으로 안내
- v2 로드맵에서 서명 + notarization 전환 검토

### 2.4 리포 구조

- 로컬 경로: `application/james-viewer/`
  (현재 Django 프로젝트 `application/james-lab/` 와 sibling 폴더)
- GitHub: 신규 별도 repo (james-lab Django repo 와 완전 분리)
- 이유: Xcode 빌드체인·`.xcodeproj`·`Package.swift` 등이 현재 Django venv 규약과 충돌. CI·Dockerfile·`.gitignore` 오염 방지

### 2.5 라이선스

- MIT (오픈소스)

### 2.6 가격

- 무료

### 2.7 언어

- 앱 UI 문자열 전부 영문
- 한국어 현지화는 v2 로드맵

### 2.8 기술 스택

- **Swift 5.9+ / Xcode 15+**
- UI: **SwiftUI**. 필요 시 AppKit wrapping 허용 (예: 커스텀 NSWindow, 드래그-드롭 처리)
- Markdown 파싱: **`swift-markdown`** (Apple 공식)
- 의존성 관리: **Swift Package Manager** 전용. CocoaPods · Carthage 금지
- 네트워크 라이브러리 금지 (뷰어는 완전 오프라인)

### 2.9 렌더링 엔진 전략 (하이브리드)

```
.md 파일 → swift-markdown 파싱 → HTML 문자열 생성 → WKWebView 표시
```

- CSS: **`github-markdown-css`** 번들 (라이트/다크 2벌, 앱에 정적 포함)
- 코드 하이라이트: **`highlight.js`** 를 WKWebView 내부에 번들된 로컬 JS 파일로 포함 (네트워크 fetch 금지)
- 이미지/로컬 파일 경로: `file://` 스킴 + `loadFileURL(_:allowingReadAccessTo:)` 로 디렉토리 기반 해결
- 선택 이유: 렌더 품질과 구현 속도의 균형, CSS 스타일링 자유도, 완전 오프라인 유지
- 대안 (채택하지 않음):
  - (a) 순수 네이티브 AttributedString: 테이블/코드블록 렌더 한계
  - (c) 완전 JS 파싱: Swift 쪽 파일 시스템·보안 컨트롤 약화

---

## 3. 지원 Markdown 기능 (MVP 범위)

### 3.1 포함 (CommonMark + GitHub Flavored Markdown)

- 헤딩 H1~H6
- 단락, 라인브레이크
- 강조: `*italic*`, `**bold**`, `~~strike~~`
- 인용, 구분선 (`---`)
- 순서 있는/없는 리스트 (중첩)
- 태스크 리스트: `- [ ]` / `- [x]`
- 인라인 코드 `` `code` ``
- 코드 블록 + 언어 감지 syntax highlighting (highlight.js)
- 테이블 (정렬 `:---:` / `---:` / `:---` 포함)
- 링크, 자동 링크
- 이미지 (상대경로·절대경로·URL)
- 각주

### 3.2 명시적 제외 (v2 로드맵으로 이관)

- LaTeX 수식 (KaTeX)
- Mermaid 다이어그램
- 목차 (TOC) 자동 생성
- 내보내기 (PDF / HTML)
- 라이브 편집
- 커스텀 컨테이너 / admonition
- frontmatter 렌더링 (단, frontmatter 자체는 파싱 전 스트립)

---

## 4. 렌더링 UX 명세 (Typora WYSIWYG 컨셉)

### 4.1 프리뷰 분할 없음

- md 원문 소스는 보이지 않음
- 오직 렌더된 결과만 표시
- 이게 Marked 2 스타일 (사이드바이사이드) 와의 차별점

### 4.2 타이포그래피

- 시스템 폰트 스택
  - 본문: `-apple-system, SF Pro Text`
  - 세리프 필요 블록 (인용 등 선택): `New York`
  - 코드: `SF Mono, Menlo`
- 기본 본문 크기 16px, 라인하이트 1.6

### 4.3 본문 폭

- 최대 폭: 760px
- 윈도우가 더 넓으면 좌우 여백 자동 중앙 정렬
- 윈도우가 더 좁으면 16px 양쪽 패딩

### 4.4 다크 모드

- macOS 시스템 appearance 자동 추종이 기본
- 사용자 수동 토글 (Shift + CMD + D) — 윈도우별 override
- 다크 CSS 는 `github-markdown-dark.css` 번들

### 4.5 줌

- CMD `+` / CMD `-`: 10% 단위 스케일 (80% ~ 200% clamp)
- CMD `0`: 100% 리셋
- 줌 상태는 윈도우별로 유지, 앱 종료 시 기본값으로 리셋

### 4.6 코드 하이라이트 테마

- 라이트: `github.css` (highlight.js 기본)
- 다크: `atom-one-dark.css`

---

## 5. 파일 오픈 · 윈도우 동작

### 5.1 오픈 방식 4가지

| # | 방법 | 비고 |
|---|---|---|
| a | Finder "Open With..." | `.md`, `.markdown` 확장자 연결 |
| b | 앱 아이콘/윈도우에 드래그 드롭 | AppKit `NSDraggingDestination` |
| c | CMD + O 다이어로그 | 시스템 파일 picker |
| d | CLI `mdv <path>` | 권장, 필수 아님. `/usr/local/bin/mdv` 심볼릭 링크 안내 |

### 5.2 윈도우

- 문서 1개 = 윈도우 1개 (싱글 문서 인터페이스)
- 탭 지원은 v2 로드맵 (macOS 시스템 탭 기본)

### 5.3 최근 파일

- "File → Open Recent" 메뉴에 최대 10개 유지
- Apple 표준 `NSDocumentController` 동작 활용
- "Clear Menu" 서브 메뉴 포함

### 5.4 파일 변경 감지

- FSEvents 로 현재 연 파일 감지
- 외부 에디터에서 md 수정 → 자동 리로드 (스크롤 위치 유지 시도)
- 삭제/이동 시 "파일이 사라졌습니다" 배너 + 재오픈 버튼

### 5.5 이미지 경로 해결

- md 파일이 열린 디렉토리를 base URL 로 사용
- 상대 경로 이미지: 해당 디렉토리 기준 resolve
- 절대 경로: `file://` 로 직접 로드
- URL (http/https): WKWebView 기본 동작으로 로드 (네트워크 허용 — 이미지 한정, JS/CSS 차단)

---

## 6. UI 구조

```
┌─────────────────────────────────────────────────┐
│ ● ● ●  JamesViewer                    🌙  − + │ ← unified titlebar
├─────────────────────────────────────────────────┤
│                                                 │
│                                                 │
│           [rendered markdown body]              │
│                                                 │
│           (max-width 760px, centered)           │
│                                                 │
│                                                 │
├─────────────────────────────────────────────────┤
│ 1,245 words · 8,912 chars · 42%               │ ← status bar
└─────────────────────────────────────────────────┘
```

- **타이틀바**: unified style. 좌측 traffic lights. 우측 appearance 토글 (🌙/☀️) + 줌 `−` `+`
- **본문**: 스크롤러, 좌우 여백 자동
- **상태바**: 단어 수 · 문자 수 · 현재 스크롤 %
- **사이드바**: MVP 없음. v2 에서 TOC / 파일 브라우저

---

## 7. 키보드 단축키

| Shortcut | Action |
|---|---|
| `⌘ O` | 파일 열기 |
| `⌘ W` | 윈도우 닫기 |
| `⌘ ,` | 환경설정 |
| `⌘ +` / `⌘ −` / `⌘ 0` | 줌 인 / 아웃 / 리셋 |
| `⌘ R` | 현재 파일 리로드 |
| `⇧ ⌘ D` | 다크 모드 수동 토글 |
| `⌘ F` | 본문 내 검색 |
| `ESC` | 검색 닫기 |
| `⌘ Q` | 앱 종료 |

환경설정(`⌘ ,`) MVP 화면은 3개 항목만:
- Default appearance (System / Light / Dark)
- Default zoom level
- `mdv` CLI 심볼릭 링크 설치/제거 버튼

---

## 8. 접근성 · 국제화

- **VoiceOver**: WKWebView 가 렌더한 시맨틱 HTML (h1~h6, p, ul, table 등) 이 기본 접근성 제공. 추가 `aria-*` 손댈 필요 없음
- **Dynamic Type**: 시스템 폰트 크기 설정 추종 (줌 레벨과 독립)
- **UI 언어**: 영어 only (v1). 한국어 현지화는 `Localizable.strings` 구조만 준비해두고 실제 번역은 v2

---

## 9. 배포 · 릴리스

### 9.1 릴리스 아티팩트

- GitHub Releases 에 **SemVer** 버전별 DMG 업로드 (`v0.1.0` 부터)
- DMG 내용:
  - `JamesViewer.app` (universal binary, unsigned)
  - `How to open.txt` — 우클릭 우회 설치 2줄 설명
  - 드래그-드롭용 `Applications` 심볼릭 링크

### 9.2 Unsigned 배포 흐름

1. 사용자가 DMG 다운로드 → 마운트 → `JamesViewer.app` 을 `Applications` 로 드래그
2. Launchpad 에서 실행 시도 → **"확인되지 않은 개발자"** 경고
3. Finder 에서 `JamesViewer.app` **우클릭 > Open** 클릭
4. "그래도 Open" 버튼 선택
5. 이후부터는 더블클릭으로 정상 실행

→ 이 절차를 README 상단에 **스크린샷 포함** 2~3단계로 명시. "이 경고는 우리가 $99/년 개발자 계정이 아직 없어서 그렇습니다" 설명 1줄.

### 9.3 앱 내 업데이트 체크

- MVP: **없음**
- "Help → Check for Updates..." 메뉴만 있고, 클릭하면 GitHub Releases 페이지 오픈
- Sparkle 통합은 v2 로드맵

### 9.4 빌드 · 출시 수동 흐름

1. Xcode → Archive
2. Organizer → Distribute App → Copy App
3. 별도 Mac 스크립트(또는 `create-dmg` 브루 패키지)로 DMG 생성
4. GitHub Releases 새 태그에 DMG 첨부 + 릴리스 노트 작성

CI 자동화 (GitHub Actions) 는 v2

### 9.5 문서

- README (EN primary, KO optional)
- CHANGELOG.md (Keep a Changelog 포맷)
- 별도 repo 안에서 관리

---

## 10. james-lab 포트폴리오 연동 (경량, **다음 세션 범위**)

### 10.1 home 4 변종에 카드 추가

- 변종: `minimal` · `magazine` · `terminal` · `studio` 전부
- 카드 내용:
  - 제목: "JamesViewer"
  - 설명 (KO/EN):
    - EN: "Minimal markdown viewer for macOS"
    - KO: "macOS 용 마크다운 뷰어"
  - CTA: "Download DMG" → GitHub Releases **latest asset URL** 로 외부 이동

### 10.2 Django 측 구현

- **별도 Django 앱을 만들지 않는다**. 카드 링크는 외부 URL 직행
- 이유: james-lab 은 웹앱 포트폴리오. Mac 네이티브 앱은 "배포된 결과물만 링크" 로 충분
- `apps/home/templates/home/_variant_*.html` 4개 파일에만 카드 추가
- `locale/ko/LC_MESSAGES/django.po` 에 신규 문자열 추가 + `makemessages` / `compilemessages`

### 10.3 CTA URL 운영

- v0.1.0 배포 전: 카드 CTA 에 "Coming Soon" 배지 (disabled)
- v0.1.0 배포 후: `https://github.com/<org>/<repo>/releases/latest/download/JamesViewer.dmg` 로 고정 링크
- 버전 올라가도 "latest" redirect 덕에 URL 불변

### 10.4 본 §10 은 스펙만 기재. 구현은 별도 세션.

---

## 11. 네거티브 규칙 (v1 에서 하지 않는 것)

- 편집 기능 일체 (WYSIWYG 타이핑, 저장, Undo)
- Markdown 확장: KaTeX 수식, Mermaid, 고급 footnote, custom container, admonition
- 내보내기: PDF / HTML / RTF
- iCloud 동기화, 파일 태깅
- Windows / Linux 지원
- 플러그인 시스템, 테마 마켓
- 앱 내 자동 업데이트 (Sparkle)
- 다중 탭 윈도우
- 결제 · 구독 · 광고
- 사용자 트래킹 / 애널리틱스 (앱은 네트워크 호출 0건)

---

## 12. 남은 미확정

### 12.1 아이콘 디자인

- 별도 디자인 세션에서 확정
- 필요 asset: 1024×1024 마스터 + macOS AppIcon set 전체 사이즈
- 컨셉 메모 (참고용, 비구속):
  - 종이/종이접기 모티프
  - 단색 1~2 톤 (브랜드 그레이 + 액센트)
  - SwiftUI SF Symbol 로 프로토타입 가능

*그 외 §2 ~ §11 전 항목 확정.*

---

## 13. v2 로드맵

### 13.1 배포 개선

- Apple Developer Program 취득 → 서명 + notarization → "더블클릭 즉시 실행" 경험
- Sparkle 기반 앱 내 자동 업데이트
- GitHub Actions 기반 DMG 빌드 자동화

### 13.2 기능 확장

- 경량 편집 모드 (WYSIWYG 타이핑, 저장 시 원본 md 그대로)
- LaTeX 수식 (KaTeX)
- Mermaid 다이어그램
- TOC 사이드바
- 파일 브라우저 사이드바 (현재 디렉토리 md 파일 리스트)
- Export: PDF / HTML
- 다중 탭 윈도우

### 13.3 국제화

- 한국어 UI 번역 (`Localizable.strings`)

### 13.4 플랫폼 확장 가능성

- Swift 네이티브 선택으로 Windows/Linux 포팅 가능성은 낮음
- 원한다면 v2+ 에서 별도 Tauri/Electron 포트를 새 프로젝트로 시작 검토

---

*끝. 아이콘 디자인 세션 + Mac 앱 구현 세션에서 §14 "구현 순서 (체크포인트 커밋)" 을 추가할 예정.*
