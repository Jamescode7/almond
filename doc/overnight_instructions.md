# Overnight 자율 실행 지시서

> 작성일: 2026-04-19
> 실행 브랜치: `restructure/add-home-app`
> 실행자: Claude Code 자율 모드 (사용자 취침 중)
> 기준 상태: Phase 0~2 완료된 시점 (home 랜딩 + quiz-bible 경로 이동 완료)

---

## 0. 실행 순서 및 정지 규칙

### 순서
1. **Task 1** — 2048 미니 게임 앱 구현 (`docs/app_02_spec.md` 기준)
2. **Task 2** — 포트폴리오 디자인 2변종 + admin 스위치 (`siteconfig` 앱 신설)
3. **Task 3** — 2048 디자인 3변종 + admin 스위치

### Cascade 정지 규칙
- Task 1 **실패 시 Task 2/3 진행 금지**
- Task 2 **실패 시 Task 3 진행 금지**
- 각 Task 완료 후 **체크포인트 커밋** + `docs/RUN_REPORT.md` 업데이트

### 공통 정지 조건 (어느 Task 중이든)
- `python manage.py check` 실패
- `makemigrations --dry-run --check` 가 **"No changes detected"가 아님**
  - 단, 새 모델(HighScore, SiteTheme) 최초 마이그레이션 생성 시는 예외 — 마이그레이션 생성 후엔 다시 "No changes"여야 함
- 동일 에러 **3회 복구 시도 실패**
- **30분 이상** 동일 이슈 교착
- 스펙에 없는 기능 추가 유혹 발생 → 하지 말고 `RUN_REPORT.md`에만 기록
- 전체 완료 시 **즉시 정지**. 시간 남아도 추가 작업 금지.

### 공통 금지 사항
- `quiz_bible` 앱 코드 수정 (home 카드 링크 유지/갱신은 예외)
- 기존 마이그레이션 파일 내용 수정
- `main` 브랜치 접근 / force push
- 새 Python 패키지 설치 (`requirements.txt` 수정 금지)
- 외부 CDN / 폰트 / 이미지 / 사운드 다운로드
- `db.sqlite3`, `.env`, `Dockerfile`, `docker-compose.yml`, `nginx.conf` 수정
- 프로덕션 배포

### 커밋 규율
- 각 체크포인트마다 커밋 1개
- 메시지는 한국어 + Co-Authored-By 포함 (기존 커밋 스타일 유지)
- 메시지 본문에 [Phase/Task 번호]와 검증 결과 요약 기입

### 보고
- 각 Task 완료 시 `docs/RUN_REPORT.md` 에 다음 형식 누적 기록:
  ```
  ## Task N — <제목>
  - 완료 시각: YYYY-MM-DD HH:MM
  - 커밋 범위: <start_hash>..<end_hash>
  - 추가된 파일: ...
  - 변경된 파일: ...
  - 발견한 이슈 / 건너뛴 항목: ...
  - 사용자 확인 필요 사항: ...
  ```

---

## Task 1 — 2048 미니 게임 앱

### 원본 스펙
**`docs/app_02_spec.md`** — 이 파일의 9번 섹션 "구현 순서 (체크포인트 커밋)" 17단계를 **위에서부터 순서대로** 실행.

### 주의 포인트
- Python 패키지명 `apps/mini_2048/`, Django `app_label='mini_2048'`, URL 슬러그 `/2048/` — 세 가지를 혼동하지 말 것
- `HighScore` 모델 최초 마이그레이션 생성 시에만 `makemigrations` 실제 실행. 이후엔 `dry-run --check` 가 "No changes"여야 함
- 클라이언트 JS는 바닐라 JS (프레임워크 금지)
- 외부 CDN/폰트/이미지/사운드 금지 — 기존 Tailwind (base.html이 이미 로드)만 사용, 추가 CSS는 `apps/mini_2048/static/mini_2048/css/game.css`에 직접 작성
- `submit_score` 뷰는 `@login_required + @require_POST` + sanity check (spec 2.4 준수)

### 완료 기준
- spec의 17단계 모두 커밋 완료
- `python manage.py check` 0 issues
- `makemigrations --dry-run --check` → No changes
- `runserver` 로 다음 경로 전부 유효한 HTTP 코드 반환:
  - `/2048/` → 200
  - `/2048/play/` → 200
  - `/2048/leaderboard/` → 200
  - `/2048/result/?score=100&tile=64` → 200
  - `/2048/api/submit-score/` (POST, 로그인 상태에서) → 200 JSON
  - `/2048/api/submit-score/` (GET) → 405
  - `/2048/api/submit-score/` (POST, 비로그인) → 302 또는 403
- home 카드의 "미니 2048" 버튼 활성화 (placeholder 상태 해제, `/2048/` 로 연결)
- `RUN_REPORT.md` 에 Task 1 섹션 기입 후 **Task 2로 넘어감**

### 실패 시 대응
- Task 1의 어느 단계에서든 정지 조건 발동 → Task 2/3 진행 금지
- `RUN_REPORT.md` 에 어디서 멈췄는지 기록

---

## Task 2 — 포트폴리오 디자인 2변종 + Admin 스위치

### 2.1 확정된 디자인 스펙

#### 변종 A: `minimal` (default)
- 현재 home 랜딩의 외관 유지
- 배경: `bg-gray-50`
- 카드: `bg-white`, 연한 그림자 (`shadow-sm`)
- 포인트: `indigo-600`
- 제목 텍스트: `text-gray-900`
- 보조 텍스트: `text-gray-500`

#### 변종 B: `dark`
- 배경: `bg-gray-900`
- 카드: `bg-gray-800`, 테두리 `border-white/10`
- 포인트: `violet-400`
- 제목 텍스트: `text-white`
- 보조 텍스트: `text-gray-400`
- 카드 hover: `hover:bg-gray-700`

#### 변동 범위 (중요)
- **색·질감만** 바뀜. 레이아웃, 구조, 컴포넌트 배치는 동일.
- 애니메이션 추가 금지, 폰트 변경 금지

### 2.2 Admin 스위칭 구조

#### 신규 앱 `apps/siteconfig/`
스캐폴드:
```
apps/siteconfig/
├── __init__.py
├── apps.py                      # name='apps.siteconfig', label='siteconfig'
├── models.py                    # SiteTheme (싱글톤)
├── admin.py
├── context_processors.py        # site_theme(request)
└── migrations/__init__.py
```

#### 모델 (정확히 이 형태로 구현)
```python
# apps/siteconfig/models.py
from django.db import models


class SiteTheme(models.Model):
    HOME_CHOICES = [
        ('minimal', 'Minimal'),
        ('dark', 'Dark'),
    ]
    G2048_CHOICES = [
        ('classic', 'Classic'),
        ('dark', 'Dark'),
        ('pastel', 'Pastel'),
    ]

    home_variant = models.CharField(
        max_length=20, choices=HOME_CHOICES, default='minimal',
        verbose_name='포트폴리오 테마',
    )
    mini_2048_variant = models.CharField(
        max_length=20, choices=G2048_CHOICES, default='classic',
        verbose_name='2048 테마',
    )
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Site Theme'
        verbose_name_plural = 'Site Theme'

    def save(self, *args, **kwargs):
        self.pk = 1  # enforce singleton
        super().save(*args, **kwargs)

    @classmethod
    def load(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return f'Theme(home={self.home_variant}, 2048={self.mini_2048_variant})'
```

#### Admin
```python
# apps/siteconfig/admin.py
from django.contrib import admin
from .models import SiteTheme


@admin.register(SiteTheme)
class SiteThemeAdmin(admin.ModelAdmin):
    list_display = ['home_variant', 'mini_2048_variant', 'updated_at']

    def has_add_permission(self, request):
        return not SiteTheme.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False
```

#### Context Processor
```python
# apps/siteconfig/context_processors.py
from .models import SiteTheme


def site_theme(request):
    try:
        return {'site_theme': SiteTheme.load()}
    except Exception:
        # DB 없는 시점 (마이그레이션 전 등) 대비
        return {'site_theme': None}
```

`app_config/settings/base.py` 의 `TEMPLATES` → `OPTIONS` → `context_processors` 에 추가:
```python
'apps.siteconfig.context_processors.site_theme',
```

`INSTALLED_APPS` 에도 `'apps.siteconfig.apps.SiteConfigConfig'` 추가.

#### base.html 수정
```html
<body class="bg-gray-50 text-gray-800 antialiased {% block body_class %}{% endblock %}">
```

→ `{% block body_class %}`를 각 페이지에서 오버라이드.

### 2.3 포트폴리오 템플릿 분기

`apps/home/templates/home/index.html` 상단에:
```django
{% block body_class %}
{% if site_theme %}theme-{{ site_theme.home_variant }}{% else %}theme-minimal{% endif %}
{% endblock %}
```

### 2.4 CSS 전략

`apps/home/static/home/css/theme.css` 신규 작성:
```css
/* minimal은 base.html의 기본 Tailwind 클래스 그대로 */
/* 카드 등은 기존 인라인 Tailwind 유지. variant 변화는 body class scoped */

/* dark 변종: 기존 Tailwind 값 오버라이드 */
body.theme-dark {
  background-color: #111827; /* gray-900 */
  color: #f9fafb;
}
body.theme-dark header {
  background-color: #1f2937; /* gray-800 */
  color: #f9fafb;
}
body.theme-dark header a {
  color: #f9fafb !important;
}
body.theme-dark a.block.bg-white {
  background-color: #1f2937 !important;
  border-color: rgba(255,255,255,0.1) !important;
}
body.theme-dark a.block.bg-white:hover {
  background-color: #374151 !important;
}
body.theme-dark h1, body.theme-dark h2 { color: #ffffff !important; }
body.theme-dark p, body.theme-dark .text-gray-500 { color: #9ca3af !important; }
body.theme-dark .bg-indigo-50 { background-color: rgba(167,139,250,0.15) !important; }
body.theme-dark .bg-amber-50 { background-color: rgba(251,191,36,0.12) !important; }
```

`index.html` 에 `{% load static %}` 후 `{% block extra_head %}<link rel="stylesheet" href="{% static 'home/css/theme.css' %}">{% endblock %}` 추가.

### 2.5 구현 순서 (체크포인트 커밋)

1. **[commit]** `apps/siteconfig/` 스캐폴드 (`__init__`, `apps.py`, 빈 `models.py`)
2. **[commit]** `SiteTheme` 모델 + 마이그레이션 생성 + `makemigrations`/`migrate` 실행
3. **[commit]** admin 등록
4. **[commit]** context_processor 추가 + `base.py` 의 `context_processors` 리스트 수정
5. **[commit]** `INSTALLED_APPS` 에 siteconfig 등록
6. **[commit]** `base.html` 에 `{% block body_class %}` 추가
7. **[commit]** `apps/home/static/home/css/theme.css` 작성 + `index.html` 에 block 오버라이드 + `extra_head` 로 CSS 로드
8. **[verify]** `manage.py check` 0 issues, `makemigrations --dry-run --check` No changes
9. **[verify]** admin 에서 SiteTheme 1개 레코드 확인 가능 (`siteconfig` 그룹 하위)
10. **[verify]** `/` 접근 시 `<body class>` 에 `theme-minimal` 포함. DB 직접 변경 (`SiteTheme.objects.filter(pk=1).update(home_variant='dark')` 가상 예시는 기록만, 실행은 admin 통해 사용자가 수동) 또는 **Django shell 로 변경** 후 `/` 재접근 시 `theme-dark` 클래스 붙음 확인
11. `RUN_REPORT.md` 에 Task 2 섹션 기입

### 2.6 Task 2 완료 기준
- 위 체크포인트 전체 커밋 완료
- `manage.py check` 0 issues
- `makemigrations --dry-run --check` No changes
- `/admin/siteconfig/sitetheme/` 접근 가능, 드롭다운 2가지 옵션 노출
- shell 에서 variant 변경 후 `/` HTML 에 body class 반영 확인 (`curl` + grep)

### 2.7 실패 시
Task 3 진입 금지. `RUN_REPORT.md` 에 기록 후 정지.

---

## Task 3 — 2048 디자인 3변종

전제: Task 1 완료 (mini_2048 앱 존재) + Task 2 완료 (SiteTheme 에 `mini_2048_variant` 필드 존재).

### 3.1 확정된 디자인 스펙

각 변종의 **타일 값별 색상 팔레트**. 폰트/레이아웃/애니메이션은 Task 1에서 정해진 기본값 그대로 둠.

#### 변종 A: `classic` (default)
원작 2048 팔레트.
- 보드 배경: `#bbada0`
- 빈 셀: `#cdc1b4`
- 타일 기본 텍스트: `#776e65`
- 타일 색 (값 → 배경/텍스트):
  - `2`: `#eee4da` / `#776e65`
  - `4`: `#ede0c8` / `#776e65`
  - `8`: `#f2b179` / `#f9f6f2`
  - `16`: `#f59563` / `#f9f6f2`
  - `32`: `#f67c5f` / `#f9f6f2`
  - `64`: `#f65e3b` / `#f9f6f2`
  - `128`: `#edcf72` / `#f9f6f2`
  - `256`: `#edcc61` / `#f9f6f2`
  - `512`: `#edc850` / `#f9f6f2`
  - `1024`: `#edc53f` / `#f9f6f2`
  - `2048`: `#edc22e` / `#f9f6f2`
  - `>=4096`: `#3c3a32` / `#f9f6f2`

#### 변종 B: `dark`
네온 톤.
- 보드 배경: `#0f172a` (slate-900)
- 빈 셀: `#1e293b` (slate-800)
- 타일 텍스트: `#ffffff`
- 타일 색 팔레트 (값↑ → 청록→자홍 그라데이션):
  - `2`: `#164e63` (cyan-900)
  - `4`: `#155e75` (cyan-800)
  - `8`: `#0e7490` (cyan-700)
  - `16`: `#0891b2` (cyan-600)
  - `32`: `#06b6d4` (cyan-500)
  - `64`: `#22d3ee` (cyan-400)
  - `128`: `#a855f7` (purple-500)
  - `256`: `#9333ea` (purple-600)
  - `512`: `#c026d3` (fuchsia-600)
  - `1024`: `#d946ef` (fuchsia-500)
  - `2048`: `#f0abfc` (fuchsia-300) + 텍스트 `#1e1b4b`
  - `>=4096`: `linear-gradient(135deg, #22d3ee, #d946ef)`

#### 변종 C: `pastel`
파스텔 톤.
- 보드 배경: `#fef3f2` (연한 로즈)
- 빈 셀: `#fce7f3` (pink-100)
- 타일 텍스트: `#374151` (gray-700)
- 타일 색:
  - `2`: `#d1fae5` (emerald-100)
  - `4`: `#a7f3d0` (emerald-200)
  - `8`: `#6ee7b7` (emerald-300)
  - `16`: `#fde68a` (amber-200)
  - `32`: `#fcd34d` (amber-300)
  - `64`: `#fbcfe8` (pink-200)
  - `128`: `#f9a8d4` (pink-300)
  - `256`: `#f472b6` (pink-400) + 텍스트 `#ffffff`
  - `512`: `#ddd6fe` (violet-200)
  - `1024`: `#c4b5fd` (violet-300)
  - `2048`: `#a78bfa` (violet-400) + 텍스트 `#ffffff`
  - `>=4096`: `#8b5cf6` (violet-500) + 텍스트 `#ffffff`

### 3.2 구현 전략

CSS는 `apps/mini_2048/static/mini_2048/css/themes.css` 에 변종별 scoped selector 로 작성.

```css
/* classic (default) */
body.theme-2048-classic .board { background: #bbada0; }
body.theme-2048-classic .cell { background: #cdc1b4; }
body.theme-2048-classic .tile[data-val="2"]    { background: #eee4da; color: #776e65; }
body.theme-2048-classic .tile[data-val="4"]    { background: #ede0c8; color: #776e65; }
/* ... */

/* dark */
body.theme-2048-dark .board { background: #0f172a; }
/* ... */

/* pastel */
body.theme-2048-pastel .board { background: #fef3f2; }
/* ... */
```

### 3.3 템플릿 분기

Task 1에서 만들어질 `apps/mini_2048/templates/mini_2048/base.html` 에 이미 `{% block body_class %}` 블록이 포함되도록 해야 함 (Task 1 구현 시 선제적으로 넣기).

만약 Task 1에서 이 블록이 누락되었다면, Task 3 진입 시 먼저 base.html 에 block 추가하는 마이크로 커밋 넣고 진행.

mini_2048 base 템플릿의 `body_class` 블록:
```django
{% block body_class %}
{% if site_theme %}theme-2048-{{ site_theme.mini_2048_variant }}{% else %}theme-2048-classic{% endif %}
{% endblock %}
```

`themes.css` 로드: mini_2048 base 의 `{% block extra_head %}` 에 추가.

### 3.4 구현 순서

1. **[commit]** mini_2048 base.html 에 `{% block body_class %}` 추가 (없었을 경우)
2. **[commit]** `apps/mini_2048/static/mini_2048/css/themes.css` 신규 작성
3. **[commit]** mini_2048 base.html `extra_head` 에서 themes.css 로드
4. **[commit]** 기존 `game.css` 에서 타일 색 하드코딩이 있다면 `themes.css` 로 이관 (없으면 skip)
5. **[verify]** shell 에서 `mini_2048_variant` 를 `dark`, `pastel` 로 바꿔가며 `curl /2048/play/` → body class 변경 확인
6. **[verify]** `makemigrations --dry-run --check` No changes (모델 변경 없으므로 당연)
7. `RUN_REPORT.md` 에 Task 3 섹션 기입
8. 전체 완료 시점에 `RUN_REPORT.md` 끝에 "모든 Task 완료" 요약 + **정지**

### 3.5 Task 3 완료 기준
- 3종 CSS 정의 완료
- admin 에서 `mini_2048_variant` 변경 가능 (Task 2에서 이미 확보됨)
- DB 값 변경 시 `/2048/play/` HTML 의 body class 반영 확인

---

## 보조 지침

### 브라우저 수동 검증 (건너뛰기)
사용자가 아침에 수행함. 자율 모드에서는 `curl -sI` 및 `curl -s | grep` 수준까지만 검증.

### 막힐 때 판단 기준
- 스펙 문서에 있는 결정 → 그대로 따름
- 스펙 문서에 없는 결정 → **최소 구현** 선택. 기능 추가하지 말 것.
- 판단 모호 → `RUN_REPORT.md` 에 "확인 필요"로 기록 후 기본값 가정하고 진행
- 치명적 오류 → 정지. 절대 destructive recovery (예: 테이블 drop, 마이그레이션 파일 삭제, `git reset --hard`) 시도 금지.

### 작업 중 참조해야 할 문서
- `docs/restructure_plan.md` — 전체 플랜, 네거티브 규칙
- `docs/app_02_spec.md` — Task 1의 단일 권위 문서
- `docs/overnight_instructions.md` — 이 파일, Task 2/3 단일 권위 문서
- `CLAUDE.md` — 가상환경 활성화 등 프로젝트 기본 정보

### venv 활성화
모든 `manage.py` 명령 전에:
```bash
source /Users/songseunghwa/Vocation/rooted155/projects/quiz_bible/application/venv/bin/activate
```

### 최종 성공 시나리오
1. `docs/RUN_REPORT.md` 에 Task 1/2/3 섹션 모두 기입
2. 마지막 줄에 "모든 Task 완료, 추가 작업 없이 정지합니다." 명시
3. 브랜치 `restructure/add-home-app` 에 깨끗한 커밋 히스토리
4. `git status` 깨끗함 (untracked 파일 없음, staged 변경 없음)
5. 사용자가 아침에 `git log --oneline` + `docs/RUN_REPORT.md` 만 봐도 상황 파악 가능

---

*끝. 위 지시 외 행동 금지. 완료 즉시 정지.*
