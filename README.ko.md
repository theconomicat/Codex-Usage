# Codex-Usage

macOS 메뉴바에서 OpenAI Codex 사용 가능량을 보여주는 작은 앱입니다.

![Codex-Usage 메뉴바 미리보기](docs/menu-bar-preview.png)

Codex-Usage는 이 Mac의 로컬 Codex 세션 로그를 읽어서 5시간 / 1주 사용 가능량을 원형 게이지로 표시합니다. 인증 토큰은 읽지 않습니다.

## 다운로드

[최신 macOS zip 다운로드](https://github.com/theconomicat/Codex-Usage/releases/latest/download/Codex-Usage-macos.zip)

압축을 풀고 `Codex-Usage.app`을 열면 됩니다. macOS가 첫 실행을 막으면 앱을 우클릭한 뒤 **Open**을 선택하세요.

## 화면

메뉴바에는 원형 게이지 두 개만 표시됩니다.

```text
(79)   (96)
```

- 왼쪽: 5시간 창에서 남은 비율
- 오른쪽: 1주 창에서 남은 비율

클릭하면 간단한 메뉴가 열립니다.

```text
5h · 79% · reset 2h
1w · 96% · reset 6d

Launch at Login
Refresh
Quit Codex-Usage
```

## 데이터

읽는 경로:

```text
~/.codex/sessions/**/*.jsonl
~/.codex/archived_sessions/*.jsonl
```

읽지 않는 것:

```text
~/.codex/auth.json
```

## 소스에서 빌드

필요한 것:

- macOS 13 이상
- Xcode command line tools
- 이 Mac에서 Codex 앱 또는 CLI를 사용한 기록

```bash
git clone https://github.com/theconomicat/Codex-Usage.git
cd Codex-Usage
./Scripts/package_app.sh
open ./Codex-Usage.app
```

계속 쓰려면 `Codex-Usage.app`을 `/Applications`로 옮기면 됩니다.

## 릴리즈 만들기

태그를 push하면 GitHub Actions가 자동으로 앱을 빌드하고 Release에 zip을 업로드합니다.

```bash
git tag v0.1.0
git push origin v0.1.0
```

로컬에서 직접 zip을 만들 수도 있습니다.

```bash
./Scripts/package_app.sh
ditto -c -k --norsrc --keepParent Codex-Usage.app Codex-Usage-macos.zip
```

## 개발

```bash
swift test
swift run CodexUsage -- --print
./Scripts/package_app.sh
```

## 주의

Codex 로컬 JSONL 포맷은 공개 API가 아닙니다. 그래서 파서는 작고 고치기 쉽게 유지합니다.

Codex가 새 로그를 쓰기 전에 reset 시간이 지나면, Codex-Usage가 해당 창을 로컬에서 자동으로 초기화합니다.

## 라이선스

MIT
