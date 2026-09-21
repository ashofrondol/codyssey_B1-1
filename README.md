# Codyssey B1-1 — 리눅스 서버 보안 & 시스템 관제 자동화

> 다중 사용자 환경의 권한 관리와 네트워크 보안 설정부터 시스템 리소스 관제와 로그 관리 자동화까지, 실제 서버 운영 흐름을 직접 구축한다.
> 실행 환경: **macOS + OrbStack Ubuntu 24.04 머신**

---

## 0. 과제 명세 (원본 미션 요구사항)

> 출처: `codyssey_assignments/B1-1.pdf` — 원문 요구사항을 그대로 옮기고, 해설은 💡 로 구분했다.
>
> 표기 규칙
> - 본문/표/코드블록에 인용된 문장·숫자·경로·명령어는 **PDF 원문 그대로**다. 임의로 다듬지 않았다.
> - `> 💡` 인용 블록과 `(해설)` 표시가 붙은 문장만이 이 문서를 쓴 조교의 해석이다.
> - 요구사항 ID(`R1`, `R1-1`, `B1` …)는 원문에 없다. 이후 절(구현·검증·자기평가)에서 참조하기 위해 **이 문서에서 부여한 것**이다.

---

### 0.1 미션 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 분야 | AI/SW 기초 |
| 구분 | Linux와 OS |
| 학습시간 | 40시간 |
| 미션 제목 | **컴퓨터가 알아서 자기 상태를 점검하게 만들기** |
| 문제 유형 | 문제기술 / 기술적 설명 |
| 개발 환경 | Ubuntu 22.04 LTS 또는 동등 리눅스 환경 |
| 구현 언어 제약 | 자동화 스크립트는 **Bash로만** |
| 제공 데이터 | `agent-app.zip` (`agent-app-linux-x86` (x86), `agent-app-linux-arm64` (arm apple)) |

#### 원문 1. 미션 소개 (그대로 옮김)

> 서버 장애가 났을 때 로그가 없으면, 원인 분석은 '감'에 의존하게 됩니다. 실제 현업에서 이런 상황이 발생하면 복구 시간이 수 배로 늘어나는 건 물론이고, 같은 장애가 반복됩니다. 권한 관리, 네트워크 보안, 로그 자동화까지 서버를 운영하는 엔지니어처럼 직접 설계합니다.
>
> 리눅스는 현대 서버 개발 및 운영 환경의 표준 운영체제 중 하나입니다. 단순히 명령어를 암기하는 1회성 학습이 아니라, 개발 커리어 내내 활용 가능한 안정적인 서버 운영 환경을 직접 구축해 보는 것이 핵심입니다.
>
> 이 미션에서는 다중 사용자 환경에서의 권한 관리와 네트워크 보안 설정을 시작으로, 실제 서비스를 배포하고 운영할 때 필수적인 시스템 리소스 관제와 로그 관리를 자동화하는 쉘 스크립트 개발을 수행합니다.
>
> 최종적으로 단순한 리눅스 사용자를 넘어, 애플리케이션 배포 환경을 구축하고 시스템의 상태를 관제하며 데이터로 기록할 수 있는 엔지니어링 역량을 갖추게 됩니다.

#### 💡 이 과제가 진짜로 묻는 것 (해설)

> 💡 **1) "Bash 스크립트를 짤 줄 아느냐"가 아니라 "운영자처럼 시스템 경계를 설계할 줄 아느냐"를 묻는다.**
> 계정 3개 · 그룹 2개 · 디렉토리 3종을 주고, **누가 무엇에 접근할 수 있어야 하는가**를 직접 매핑하게 만든다. `agent-common`(공유)과 `agent-core`(보안)를 나눈 것이 문제의 핵심 설계 포인트다.
>
> 💡 **2) "죽일 실패"와 "알릴 실패"를 구분하는 감각을 묻는다.**
> 프로세스·포트 이상은 `exit 1`(치명적), 방화벽 비활성·임계값 초과는 `[WARNING]`만 출력하고 계속 진행(운영 경고). 이 둘을 뒤섞으면 요구사항을 정면으로 위반한다. 체크리스트에도 따로 질문으로 등장한다.
>
> 💡 **3) "사람이 실행하는 스크립트"가 아니라 "cron이 실행하는 스크립트"를 묻는다.**
> 작성자는 `agent-dev`, 실행자는 `agent-admin`, 권한은 `750`. 이 세 조건이 동시에 성립하려면 `agent-admin`이 그룹 `agent-core`에 속해야만 한다 — 권한 비트와 그룹 멤버십이 맞물리는 퍼즐이다. 게다가 cron 환경은 로그인 셸 환경변수를 상속하지 않는다.
>
> 💡 **4) "로그를 남겼느냐"가 아니라 "로그가 시스템을 죽이지 않게 했느냐"를 묻는다.**
> 10MB/10개 보존 정책, 보너스의 7일 압축 / 30일 삭제는 전부 "로그가 디스크를 채우는 사고"에 대한 대비다.
>
> 💡 **5) 제공된 Python 앱은 채점 대상이 아니다.** 원문이 못박았다 — "제공된 Python 앱은 '실행 대상'이며, 과제의 핵심은 관제/자동화 스크립트 구현이다." 앱을 고치거나 다시 만들 필요가 없다.

---

### 0.2 최종 산출물 (제출물)

#### 원문 2. 최종 결과물

> 다음 2가지 산출물을 제출해야 한다.

**1. 요구사항 수행 내역서(문서 1개)**

- 수행 내역
  - 설정/명령어 기록 (SSH 포트, 방화벽 규칙, 계정/그룹/ACL, 디렉토리/권한, 환경 변수, cron 등록 등)

**필수 증거 자료 체크리스트** (원문 그대로 — 8개 전부가 제출 문서에 들어가야 한다)

- [ ] SSH 포트 변경(20022) 및 Root 원격 접속 차단 설정 확인 내역
- [ ] 방화벽(UFW 또는 firewalld) 활성화 및 20022/tcp, 15034/tcp만 허용 내역
- [ ] 계정/그룹(agent-admin/dev/test, agent-common/core) 생성 확인 내역
- [ ] 디렉토리 구조 및 권한(ACL 포함) 확인 내역
- [ ] 앱 Boot Sequence 5단계 [OK] 및 “Agent READY” 확인 내역
- [ ] monitor.sh 실행 결과(프로세스/포트/리소스/경고) 내역
- [ ] /var/log/agent-app/monitor.log 누적 기록 확인(최근 라인) 내역
- [ ] crontab 매분 실행 등록 및 자동 실행 확인(1분 후 로그 증가) 내역

**2. 자동화 스크립트 소스코드**

- `monitor.sh` : 시스템 상태 수집 및 로깅 스크립트

> 💡 (해설) 증거 자료 체크리스트 8항목은 사실상 **채점 항목 그 자체**다. 각 항목이 "설정했다"가 아니라 "**확인 내역**"을 요구한다는 점에 주의 — 설정 파일 내용뿐 아니라 `ss -tulnp`, `ufw status`, `id`, `ls -l`, `getfacl`, `crontab -l`, `tail monitor.log` 같은 **검증 명령의 실행 결과(터미널 캡처/출력)** 가 있어야 증거로 성립한다. 특히 마지막 항목은 "1분 후 로그 증가"라는 **시간 간격을 둔 before/after 2회 캡처**를 요구한다.

---

### 0.3 과제 목표 — 수료 후 스스로 설명할 수 있어야 하는 것

#### 원문 3. 과제 목표

> 이 과제를 마친 후, 학습자는 아래를 스스로 설명할 수 있어야 한다.

- [ ] **G1.** SSH 포트 변경과 Root 원격 접속 차단이 왜 기본 보안에 해당하는지 설명할 수 있다.
- [ ] **G2.** UFW 또는 firewalld 중 하나를 선택해 “필요 포트만 허용”하는 방화벽 정책을 구성하고 검증할 수 있다.
- [ ] **G3.** 역할 기반 계정/그룹과 ACL을 통해 “공유 디렉토리”와 “보안 디렉토리”를 분리하는 이유를 설명할 수 있다.
- [ ] **G4.** 환경 변수(AGENT_HOME 등)로 실행 환경을 고정하는 이유와 검증 방법을 설명할 수 있다.
- [ ] **G5.** 쉘 스크립트로 프로세스/포트/리소스 상태를 수집하고, 로그로 남겨 운영 문제를 추적하는 흐름을 설명할 수 있다.
- [ ] **G6.** crontab으로 모니터링을 주기 실행시키고, 로그 보존 정책(압축/삭제)이 왜 필요한지 설명할 수 있다.

> 💡 (해설) 목표가 전부 "**설명할 수 있다**"로 끝난다. 즉 이 과제는 동작하는 결과물만으로는 절반만 끝난 것이고, **왜 그렇게 했는지 구술할 수 있어야** 완성이다. 평가 체크리스트의 2·3·4절(구현 구조 설명 / 핵심 개념 이해 / 확장 사고)이 정확히 이 목표들을 되묻는다.

---

### 0.4 기능 요구 사항 (필수)

#### 원문 4. 기능 요구 사항

> 다음 요구사항을 모두 만족해야 한다.

#### R1. 기본 보안 및 네트워크 설정

**SSH 설정**

- [ ] **R1-1** SSH 접속 포트를 **20022**로 변경한다.
- [ ] **R1-2** **Root 원격 로그인을 차단**한다.

> 확인 방법(예시)
> - sshd 설정 파일에서 포트/PermitRootLogin 확인
> - 포트 리슨 상태 확인: `ss -tulnp` 후 sshd 관련 라인 확인

**방화벽 설정(택1)**

- [ ] **R1-3** **UFW 또는 firewalld 중 하나**를 선택해 활성화한다.
- [ ] **R1-4** 인바운드 허용 포트는 **TCP 20022(SSH), TCP 15034(APP)만** 허용한다.

> 확인 방법(예시)
> - UFW 선택 시: `ufw status`
> - firewalld 선택 시: `firewall-cmd --list-all`

> 💡 (해설) "만 허용한다"는 화이트리스트 요구다. 기본 정책이 deny여야 성립하며, 기존에 열려 있던 22/tcp 규칙이 남아 있으면 R1-4 위반이다. 또한 **R1-1을 적용하기 전에 R1-3/R1-4를 먼저 적용하면 자기 자신을 잠글 수 있다** — 20022 허용 → sshd 포트 변경 → sshd 재시작 → 새 세션으로 접속 확인 → 그 다음에 22 차단, 순서가 안전하다.

#### R2. 계정/그룹/권한 체계(협업 + 최소 권한)

**생성 계정**

- [ ] **R2-1** 다음 3개 계정을 생성한다.

| 계정 | 역할 (원문) |
| --- | --- |
| `agent-admin` | 운영/관리, cron 실행자 |
| `agent-dev` | 개발/운영, monitor.sh 작성자 |
| `agent-test` | QA/테스트 |

**생성 그룹**

- [ ] **R2-2** 다음 2개 그룹을 생성하고 멤버를 구성한다.

| 그룹 | 멤버 (원문) |
| --- | --- |
| `agent-common` | admin, dev, test |
| `agent-core` | admin, dev |

**디렉토리 구조(AGENT_HOME 기준)**

- [ ] **R2-3** 다음 디렉토리를 만든다.

```
$AGENT_HOME
$AGENT_HOME/upload_files
$AGENT_HOME/api_keys
/var/log/agent-app
```

**접근 권한(핵심 정책)**

- [ ] **R2-4** `upload_files`: **group=agent-common, R/W 가능**
- [ ] **R2-5** `api_keys` 및 `/var/log/agent-app`: **group=agent-core ONLY, R/W 가능**

> 확인 방법(예시)
> - `id agent-admin` / `id agent-dev` / `id agent-test`
> - `ls -l` 및 `getfacl`(사용 시)로 소유/권한 확인

> 💡 (해설) `agent-core ONLY`는 "**agent-test는 읽지도 못해야 한다**"는 뜻이다. 그러므로 others 비트는 `---`(0)이어야 하고, 디렉토리는 실행 비트까지 포함해 `0770`/`2770` 수준이 필요하다(디렉토리의 `x`는 진입 권한). 새로 만들어지는 파일의 그룹을 고정하려면 **setgid 비트(`chmod g+s`)** 가, 기본 권한까지 강제하려면 **ACL의 default 엔트리(`setfacl -d -m`)** 가 실질적으로 필요하다 — 원문이 "ACL 포함"을 증거 체크리스트에 넣은 이유다.

#### R3. 애플리케이션 실행 환경 구성(제공 Python 앱)

**환경 변수**

- [ ] **R3-1** 다음 환경 변수를 설정한다.

| 변수 | 값 (원문) |
| --- | --- |
| `AGENT_HOME` | 예) `/home/agent-admin/agent-app` |
| `AGENT_PORT` | `15034` |
| `AGENT_UPLOAD_DIR` | `$AGENT_HOME/upload_files` |
| `AGENT_KEY_PATH` | `$AGENT_HOME/api_keys/t_secret.key` |
| `AGENT_LOG_DIR` | `/var/log/agent-app` (미지정 시 기본값이므로 지정 권장) |

**키 파일 생성**

- [ ] **R3-2** 경로: `$AGENT_HOME/api_keys/t_secret.key` / 내용: `agent_api_key_test` (**1줄**)

**앱 실행 및 성공 기준**

- [ ] **R3-3** **일반 계정으로 실행(루트 실행 금지)**
- [ ] **R3-4** **Boot Sequence 5단계가 모두 `[OK]`로 출력**되고, 마지막에 **“Agent READY”** 가 출력되어야 한다.
- [ ] **R3-5** 앱이 **`0.0.0.0:15034`로 LISTEN 상태**가 되어야 한다.

> 참고: 앱 종료는 Ctrl+C로 수행한다.

> 💡 (해설) `AGENT_HOME`은 "예)"로 제시되었으므로 경로 자체는 바꿔도 되지만, **바꾼 값이 R4의 `$AGENT_HOME/bin/monitor.sh`, R3-2의 키 경로, 앱이 읽는 값과 전부 일치**해야 한다. 그리고 `0.0.0.0` LISTEN은 `127.0.0.1`과 다르다 — 루프백 바인딩이면 R3-5 미달이며, R1-4에서 15034를 방화벽에 연 것도 의미가 없어진다.

#### R4. 시스템 관제 자동화 스크립트(monitor.sh) 구현

**파일 위치/권한 정책**

- [ ] **R4-1** 경로: `$AGENT_HOME/bin/monitor.sh` / 소유자: `agent-dev` / 그룹: `agent-core` / 권한: **750 (rwxr-x---)**
- [ ] **R4-2** cron 실행 계정: `agent-admin` (**agent-admin은 agent-core에 포함되어 실행 가능해야 함**)

**Health Check(실패 시 종료)**

- [ ] **R4-3** 프로세스: `agent_app.py`(또는 제공 앱 파일명) 실행 상태를 확인하고, **비정상 시 `exit 1`**
- [ ] **R4-4** 포트: **TCP 15034 LISTEN 상태 확인**, 비정상 시 **`exit 1`**

**상태 점검(경고만 출력)**

- [ ] **R4-5** 방화벽(UFW 또는 firewalld) 활성화 상태를 점검한다. 비활성 상태면 **`[WARNING]`을 출력하되, 스크립트는 종료하지 않는다.**

**자원 수집**

- [ ] **R4-6** 다음 3가지를 수집한다.
  - CPU 사용률(%)
  - 메모리 사용률(%)
  - 디스크 사용률(**Root partition, Used %**)

**임계값 경고(경고만 출력)**

- [ ] **R4-7** 아래 임계값 초과 시 `[WARNING]`을 출력한다(종료하지 않는다).

| 지표 | 임계값 | 동작 |
| --- | --- | --- |
| CPU | **> 20%** | `[WARNING]` |
| MEM | **> 10%** | `[WARNING]` |
| DISK_USED | **> 80%** | `[WARNING]` |

**로그 기록**

- [ ] **R4-8** 로그 파일: `/var/log/agent-app/monitor.log` / 로그 포맷:

```
[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
```

**로그 파일 용량 관리**

- [ ] **R4-9** monitor.log가 커지면 **최대 10MB/10개 파일 유지**(방법 자유: logrotate 사용 또는 스크립트 로직 구현)

> 💡 (해설) R4-3/R4-4(치명 → `exit 1`)와 R4-5/R4-7(경고 → 계속 진행)의 분리가 이 요구사항의 채점 급소다. 또 하나 — R4-8 포맷에 `PID:...`가 들어 있으므로, **R4-3에서 찾은 PID를 변수로 들고 있다가 로그 라인에 써야** 한다. 임계값이 CPU 20% / MEM 10%로 비현실적으로 낮은 것은 의도적이다: **평상시에도 경고가 떠서 경고 경로가 실제로 동작하는지 증거를 남길 수 있게** 하려는 설정이다(예시 출력도 25.3%로 경고가 뜬 상태다).

#### R5. 자동 실행(cron) 설정

- [ ] **R5-1** **agent-admin 계정의 crontab**으로 monitor.sh를 **매분** 실행되도록 등록한다.
- [ ] **R5-2** 등록 후 **1~2분 내** monitor.log에 **새 라인이 자동으로 누적**되는 것을 확인한다.

> 💡 (해설) cron은 로그인 셸의 `~/.bashrc`/`~/.profile`을 읽지 않는다. `$AGENT_HOME` 같은 환경 변수에 의존하는 스크립트는 cron에서 **빈 값으로 터진다**. 스크립트 안에서 기본값을 정의하거나(`: "${AGENT_HOME:=/home/agent-admin/agent-app}"`), crontab 상단에 변수를 선언하거나, 절대 경로만 쓰는 방식 중 하나를 택해야 한다. `PATH`도 최소값(`/usr/bin:/bin`)이라 `ss`, `ufw` 같은 `/usr/sbin` 계열 명령이 안 잡힐 수 있다.

---

### 0.5 보너스 과제 (선택)

#### 원문 5. 보너스 과제 (선택)

#### B1. 보너스 1 – report.sh로 요약 리포트 자동 생성

- [ ] **B1-1** monitor.log를 분석해 **CPU/MEM/DISK의 평균/최대/최소와 샘플 수**를 **콘솔로 출력**한다.
- [ ] **B1-2** (선택) **시작/종료 시간을 입력받아 해당 구간의 로그만** 분석한다.

#### B2. 보너스 2 – 시간 기반 로그 보존 정책(압축/아카이브/삭제)

- [ ] **B2-1** **7일 경과 로그 압축** — 대상: `/var/log/agent-app/*.log` 중 **7일 이상 경과** 파일
- [ ] **B2-2** **아카이브 이동** — 경로: `/var/log/monitor/agent-app/archive/`
- [ ] **B2-3** **30일 경과 아카이브 삭제** — 대상: `/var/log/monitor/agent-app/archive/*.gz` 중 **30일 이상 경과** 파일
- [ ] **B2-4** (권장) **예외 처리 포함** — 디렉토리 미존재, 권한 부족, 대상 파일 0개 등에서 “안전하게 종료/경고”하도록 처리

> 💡 (해설) B2의 아카이브 경로가 `/var/log/agent-app/archive/`가 아니라 **`/var/log/monitor/agent-app/archive/`** 라는 점에 주의하라(원문 그대로). 로그 원본 디렉토리와 아카이브 디렉토리가 **다른 트리**에 있다. 그리고 B2(시간 기반: 7일/30일)는 R4-9(용량 기반: 10MB/10개)를 **대체하지 않는다** — 둘은 별개의 정책이고 R4-9는 필수, B2는 선택이다.

---

### 0.6 개발 환경 · 제약 사항

#### 원문 6. 개발 환경

- Ubuntu 22.04 LTS 또는 동등 리눅스 환경
- 이전 미션에서 구성한 Linux 실습 환경(컨테이너/VM)을 그대로 사용 권장

#### 원문 7. 제약 사항

**구현 언어/도구**

> ⛔ **자동화 스크립트는 Bash로만 작성한다(Python 등으로 대체 금지)**
>
> ⛔ **필요한 경우에만 sudo 사용(가능한 일반 계정으로 진행)**

**Test Case / 제공 애플리케이션**

> 제공된 Python 앱은 “실행 대상”이며, **과제의 핵심은 관제/자동화 스크립트 구현이다.**

#### 데이터 (원문 9페이지)

| 항목 | 내용 |
| --- | --- |
| 데이터파일 | `agent-app.zip`, 단위문제 PDF 파일 |
| 데이터파일설명 | `agent-app-linux-x86` (x86) / `agent-app-linux-arm64` (arm apple) |

> 💡 (해설) 금지 사항을 다시 못박으면 — **`monitor.sh`와 (보너스의) `report.sh`에 Python·Perl·Node를 끼워 넣으면 안 된다.** 평균/최대/최소 계산도 `awk`, `bc`, 또는 Bash 산술로 해결해야 한다(`awk`는 외부 명령이지 다른 구현 언어가 아니므로 통상 허용 범위로 본다 — 💡 추론). 또한 제공 앱은 x86/arm64 **바이너리 2종**으로 배포되므로, 실습 머신의 아키텍처에 맞는 쪽을 골라야 한다. 다만 R4-3의 프로세스 이름은 원문이 `agent_app.py`(또는 제공 앱 파일명)라고 적었으므로, **실제로 뜨는 프로세스 이름을 `ps`로 먼저 확인**한 뒤 그 이름으로 감시해야 한다.

---

### 0.7 결과/출력 예시

#### 원문 8. 결과 예시

> 아래는 **정답이 아니라 참고 예시**다. 실제 문구와 구성은 달라도 된다.

**앱 Boot Sequence 출력 예시**

```
> Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
... Running as service user 'agent-admin' (uid=1001)
[2/5] Verifying Environment Variables     [OK]
... All required Envs correct
[3/5] Checking Required Files             [OK]
... Verified key file with correct key string.
[4/5] Checking Port Availability          [OK]
... Port 15034 is available.
[5/5] Verifying Log Permission            [OK]
... Log directory is writable: /var/log/agent-app
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
```

**monitor.sh 콘솔 출력 예시**

```
====== SYSTEM MONITOR RESULT ======
[HEALTH CHECK]
Checking process 'agent_app.py'... [OK] (PID: 48291)
Checking port 15034... [OK]

[RESOURCE MONITORING]
CPU Usage : 25.3%
MEM Usage : 5.2%
DISK Used  : 23%

[WARNING] CPU threshold exceeded (25.3% > 20%)

[INFO] Log appended: /var/log/agent-app/monitor.log
```

**monitor.log 누적 예시**

```
[2026-02-25 13:58:01] PID:48291 CPU:10.2% MEM:3.2% DISK_USED:23%
[2026-02-25 13:59:01] PID:48291 CPU:18.7% MEM:5.0% DISK_USED:23%
[2026-02-25 14:00:01] PID:48291 CPU:25.3% MEM:9.8% DISK_USED:23%
```

**(보너스 수행 시) report.sh 콘솔 출력 예시**

```
====== STATISTICS REPORT ======
  [CPU]
    Average : 21.4%
    Maximum : 25.3% at 2026-02-25 14:00:05
    Minimum : 10.2% at 2026-02-25 13:58:05
  [Memory]
    Average : 6.1%
    Maximum : 9.8% at 2026-02-25 14:00:05
    Minimum : 3.2% at 2026-02-25 13:58:05
  [Samples]
    Data Points: 10 samples
```

> 💡 (해설, 원문 대조 시 주의) PDF 8페이지의 report.sh 예시에서 최대/최소 시각이 `14:00:05` / `13:58:05`로 찍혀 있으나, 같은 PDF의 monitor.log 예시 라인은 `14:00:01` / `13:58:01`이다. **원문 예시 자체의 초(sec) 불일치**이며 요구사항이 아니다. "정답이 아니라 참고 예시"라고 명시되어 있으므로 형식만 참고하면 된다.
>
> 💡 로그 누적 예시의 타임스탬프 간격이 정확히 **1분**(13:58 → 13:59 → 14:00)인 점에 주목하라. R5-1의 "매분 실행"이 제대로 걸렸을 때 나오는 모습이며, 이 간격이 불규칙하거나 비어 있으면 cron이 실패하고 있다는 신호다.

---

### 0.8 📚 이 과제가 공부하길 원하는 것 (학습 지도)

> 💡 아래 표 전체가 조교의 해설이다. PDF의 각 요구사항이 겨냥하는 CS/엔지니어링 개념과, 평가 체크리스트(`checklists_md/ssh_security_monitoring.md`)의 "핵심 개념 이해" · "확장 사고 및 트러블슈팅" 질문을 연결해 두었다. **결과물보다 이 표의 마지막 열에 답할 수 있는지가 이 과제의 실제 합격선이다.**

| 요구사항 | 표면적으로 시키는 일 | 실제로 학습시키려는 개념 | 스스로 답해볼 질문 |
| --- | --- | --- | --- |
| **R1-1, R1-2** | sshd_config에서 Port를 20022로 바꾸고 PermitRootLogin을 끈다 | **위협 모델링과 공격 표면(attack surface) 축소.** 포트 변경은 암호학적 방어가 아니라 자동화 스캐너/봇넷의 대량 무차별 대입을 걸러내는 **노이즈 감소**이고, root 차단은 "알려진 계정명 + 최고 권한"이라는 단일 실패점을 없애 공격자가 *계정명까지 추측*하게 만드는 **다단계 방어**다. sudo를 통한 권한 상승은 감사 로그가 남는다는 점도 핵심 | 포트를 20022로 바꾸는 것은 "보안"인가 "은폐(security through obscurity)"인가? 둘 다라면 각각 어디까지 유효한가? root를 막아도 sudo 계정이 털리면 결과가 같은데, 그럼에도 막는 이유는? |
| **R1-3, R1-4** | UFW/firewalld를 켜고 2개 포트만 연다 | **기본 거부(default-deny) 정책과 화이트리스트 사고.** "위험한 것을 막는다"가 아니라 "필요한 것만 연다"로 사고를 뒤집는 훈련. 방화벽은 상태 추적(stateful) 필터이며, iptables/nftables 위의 추상화 계층이라는 구조 이해 | 왜 "22를 닫는다"가 아니라 "20022와 15034만 연다"라고 써야 안전한가? 방화벽을 켜는 순간 내 SSH 세션이 끊길 수 있는 시나리오는? 그걸 막는 작업 순서는? |
| **R2-1, R2-2** | 계정 3개, 그룹 2개를 만든다 | **역할 기반 접근 제어(RBAC)의 최소 단위.** 사용자를 직접 권한에 묶지 않고 *역할(그룹)* 을 한 겹 끼워 넣으면, 인원이 바뀌어도 권한 정책은 그대로 유지된다. `/etc/passwd`, `/etc/group`, primary vs. supplementary group의 차이 | agent-dev가 퇴사하고 agent-dev2가 들어오면 몇 개의 설정을 고쳐야 하는가? 그룹을 안 쓰고 파일마다 권한을 줬다면 몇 개였을까? primary group과 secondary group은 파일 생성 시 무엇이 달라지는가? |
| **R2-4 vs R2-5** | upload_files는 common, api_keys와 로그는 core만 | **최소 권한 원칙(Principle of Least Privilege)과 데이터 분류.** 같은 서버 안에서도 "공유해도 되는 데이터"와 "샐 경우 치명적인 데이터(API 키, 로그)"를 물리적으로 분리하는 설계. 침해 시 폭발 반경(blast radius)을 줄이는 것이 목적 | agent-test가 API 키를 읽을 수 있으면 구체적으로 무슨 사고가 가능한가? **로그 디렉토리**까지 core로 묶은 이유는? (힌트: 로그에는 경로·PID·내부 구조가 다 적혀 있다) |
| **R2-3, R2-5** | ls -l과 getfacl로 권한을 확인한다 | **전통 권한 비트(rwx/ugo)의 한계와 POSIX ACL.** "한 디렉토리에 두 그룹이 다른 권한으로 접근"은 owner/group/other 3칸으로는 표현이 불가능하다. 여기서 `setfacl`, default ACL, setgid 디렉토리, umask가 왜 존재하는지가 체감된다 | rwx 9비트만으로 R2-4와 R2-5를 동시에 만족시킬 수 있는가? 새로 만든 파일이 자동으로 agent-core 그룹을 갖게 하려면 무엇이 필요한가? `ls -l`에 `+` 기호가 뜨는 건 무슨 뜻인가? |
| **R3-1, R3-2** | 환경 변수 5개를 정의하고 키 파일을 만든다 | **설정의 외부화(12-Factor App의 Config)와 실행 환경 고정.** 코드에 경로를 박지 않고 환경 변수로 주입하면 동일 바이너리를 dev/prod에 그대로 배포할 수 있다. 동시에 "환경 변수는 어디에 정의되며 누가 상속받는가"라는 프로세스 환경 상속 모델을 배운다 | `export`한 변수는 어느 프로세스까지 전달되는가? `~/.bashrc`에 쓴 변수가 cron·systemd에서 안 보이는 이유는? 비밀 키를 환경 변수 값 자체로 넣지 않고 **파일 경로**(`AGENT_KEY_PATH`)로 준 이유는? |
| **R3-3** | 루트로 실행하지 말라 | **서비스 계정(service account) 개념과 권한 분리.** 애플리케이션이 root로 돌면 앱의 취약점이 곧바로 시스템 장악으로 이어진다. 1024 미만이 아닌 15034를 앱 포트로 고른 것도 "비특권 포트라 일반 계정이 바인딩할 수 있게" 하려는 설계 | 앱 포트가 80이었다면 무엇이 달라졌겠는가? root로 실행해도 "일단 동작은 하는데" 왜 감점 사유인가? |
| **R3-4, R3-5** | Boot Sequence 5단계 [OK]와 0.0.0.0:15034 LISTEN 확인 | **기동 시 사전 검증(preflight check)과 소켓 바인딩 주소의 의미.** 앱이 "일단 뜨고 나중에 죽는" 대신 시작 시점에 계정·환경변수·파일·포트·로그권한을 스스로 검사하는 패턴. `0.0.0.0` vs `127.0.0.1` vs `::` 바인딩 차이 | 5단계 중 하나라도 실패하면 앱은 어떻게 행동해야 옳은가? `127.0.0.1:15034`로 뜨면 방화벽에서 15034를 열어둔 게 왜 무의미해지는가? `ss -tulnp` 출력의 각 열은 무엇을 뜻하는가? |
| **R4-1, R4-2** | 소유자 agent-dev, 그룹 agent-core, 권한 750 | **소유자·그룹·권한 비트가 맞물리는 실행 가능성 계산.** 750은 owner=rwx, group=r-x, other=---. 실행자 agent-admin은 owner가 아니므로 **group 비트로만** 실행 권한을 얻는다 → agent-admin이 agent-core 멤버가 아니면 cron은 조용히 "Permission denied"로 실패한다 | agent-admin을 agent-core에서 빼면 정확히 어느 단계에서 무슨 에러가 나는가? 740이었다면? 755였다면 무엇이 위험해지는가? 그룹 추가 후 즉시 반영되지 않는 이유(세션 재로그인)는? |
| **R4-3, R4-4** | pgrep/ps로 프로세스, ss/netstat로 포트를 본다 | **liveness와 readiness의 차이.** 프로세스 존재는 "살아 있음"일 뿐이고 포트 LISTEN이 "일을 받을 준비됨"이다. 두 개를 **따로** 검사하라는 요구 자체가 이 구분을 가르친다. 더불어 명령 선택의 근거(`pgrep -f`의 부분 매칭 위험, `ss`가 `netstat`를 대체한 이유) | **"프로세스는 살아 있는데 포트가 안 열린다"** — 원인 후보를 몇 개 댈 수 있는가(기동 중/데드락/바인딩 실패/다른 주소에 바인딩/방화벽)? 확인 순서는? `pgrep -f agent_app.py`가 **자기 자신인 monitor.sh를** 잡아버리는 사고는 왜 생기는가? |
| **R4-3/R4-4 vs R4-5/R4-7** | 어떤 건 exit 1, 어떤 건 WARNING만 | **장애(fault)와 성능 저하(degradation)의 분리 — 알림 피로(alert fatigue) 설계.** 서비스가 죽은 것은 즉시 조치 대상이고, CPU가 높은 것은 추세로 봐야 할 지표다. 둘을 같은 심각도로 다루면 알림이 무의미해진다. 또한 `exit` 코드는 cron·상위 감시 도구가 읽는 **기계용 인터페이스**다 | 방화벽이 꺼져 있는데도 스크립트를 계속 진행시키는 이유는? CPU 초과에서 exit 1을 했다면 cron 로그와 로그 파일에 무슨 일이 벌어지는가? exit 0과 exit 1을 누가 읽는가? |
| **R4-6, R4-7** | CPU/MEM/DISK를 뽑아 임계값과 비교 | **관측 지표의 정의와 텍스트 파싱.** "CPU 사용률"의 정의가 여러 개다(순간값 vs 평균, `top -bn1`의 첫 샘플은 부팅 후 누적치라 부정확). 디스크는 "Root partition의 Used %"로 **대상이 명시**되어 있다. `top`/`free`/`df`/`/proc/stat`의 출력 구조와 `awk` 필드 파싱, 부동소수 비교를 Bash에서 하는 법(`bc`, `awk`) | `top -bn1`의 첫 번째 CPU 값을 그대로 쓰면 왜 틀리는가? `free`의 free / available / used 중 "메모리 사용률"에 맞는 것은? `df`에서 루트 파티션 한 줄만 고르는 방법은? Bash의 `[ ]`로 `25.3 > 20`을 왜 못 비교하는가? |
| **R4-8** | 지정 포맷으로 로그를 한 줄씩 쌓는다 | **구조화된 로깅과 기계 가독성.** 포맷을 고정하는 이유는 사람이 보기 좋아서가 아니라 **나중에 파싱하기 위해서**다 — 보너스 report.sh가 바로 그 소비자다. 고정폭 타임스탬프(`YYYY-MM-DD HH:MM:SS`)는 문자열 정렬 = 시간 정렬이 되는 형식이다. 그리고 `>`(truncate)와 `>>`(append)의 차이, 파일 디스크립터와 O_APPEND 의미 | `>`를 썼다면 cron 1분 뒤 로그 파일에 몇 줄이 남는가? 타임스탬프를 `2/25/26 2:00 PM`으로 찍었다면 report.sh의 구간 필터는 왜 어려워지는가? 여러 프로세스가 동시에 같은 로그에 `>>` 하면 왜 대체로 안전한가? |
| **R4-9** | 10MB/10개로 유지한다 | **로그 로테이션과 디스크 고갈 방어.** 무한히 자라는 파일은 결국 디스크를 채우고 *다른 모든 서비스*를 죽인다(로그가 장애의 원인이 되는 전형적 사고). logrotate의 size/rotate/copytruncate 옵션이 어떻게 동작하는지, 왜 열린 파일을 단순 `rm` 하면 공간이 안 돌아오는지(inode 참조) | 10MB × 10개 = 최대 몇 MB를 보장하는가? logrotate가 파일을 옮긴 뒤에도 앱이 옛 파일에 계속 쓰는 문제는 왜 생기며 `copytruncate`는 어떻게 푸는가? 스크립트 로직으로 구현한다면 로테이션 판단은 언제 해야 하는가(쓰기 전/후)? |
| **R5-1, R5-2** | crontab에 `* * * * *` 등록 | **스케줄링과 비대화형 실행 환경.** cron은 `~/.bashrc`를 읽지 않고 PATH가 최소이며 TERM·HOME·LANG이 다르다 → "터미널에서는 되는데 cron에서는 안 되는" 고전적 함정. 사용자별 crontab의 소유·실행 주체, 출력이 메일로 가는 동작, systemd timer라는 대안 | 손으로 실행하면 되는데 cron에서만 실패하는 이유 5가지를 댈 수 있는가? 실행 주체를 root가 아닌 agent-admin으로 지정한 이유는? 스크립트가 1분보다 오래 걸리면 어떤 일이 생기는가(중첩 실행)? |
| **B1 (report.sh)** | 로그를 읽어 평균/최대/최소/샘플수 출력 | **로그를 데이터로 소비하기 — 관측(monitoring)에서 분석(analytics)으로.** 자신이 정한 포맷을 자신이 파싱해 보면서 "포맷 설계가 곧 API 설계"임을 체감한다. `awk`의 레코드/필드 모델, 누적 집계, 최대·최소와 함께 *그 시점*까지 기록하는 패턴 | 로그 포맷을 한 글자라도 바꾸면 report.sh의 어디가 깨지는가? 그 결합을 줄이려면(정규식/구분자/키=값) 어떤 포맷이 나았겠는가? 샘플이 0개일 때 평균은 무엇을 출력해야 하는가? |
| **B2 (보존 정책)** | 7일 압축 → 아카이브 이동 → 30일 삭제 | **데이터 수명주기 관리(hot/warm/cold)와 배치 작업의 방어적 작성.** 최근 로그는 빠르게, 오래된 로그는 압축해 싸게, 아주 오래된 건 폐기. `find -mtime`의 경계 의미(+7의 실제 조건), `find -print0` + `xargs -0`로 공백/특수문자 대응, 멱등성(같은 배치를 두 번 돌려도 안전한가) | `find -mtime +7`은 정확히 "7일 이상"인가 "8일 이상"인가? 대상 파일이 0개일 때 스크립트가 에러로 죽으면 cron 알림은 어떻게 되는가? 압축 중 전원이 나가면 원본과 .gz이 둘 다 남는가? |
| **G1~G6 전체** | (문서로 설명) | **운영 문서화와 재현 가능성.** 증거 체크리스트 8항목은 "나 말고 다른 사람이 이 서버를 이어받을 수 있는가"를 묻는다. 명령어 기록이 곧 IaC(Infrastructure as Code)의 원시 형태이며, 여기서 Ansible/Dockerfile의 필요성이 자연스럽게 도출된다 | 이 서버가 내일 날아가면 내 문서만으로 몇 분 만에 복구할 수 있는가? 수동으로 한 설정 중 자동화하지 않으면 반드시 빠뜨릴 것은 무엇인가? |
| **확장 사고 (체크리스트 4절)** | — | **감시 대상의 일반화.** monitor.sh는 사실 "프로세스 이름 / 포트 번호 / 로그 경로 / 임계값" 4개의 파라미터를 가진 템플릿이다. 이걸 인식하면 대상이 Nginx든 PostgreSQL이든 바뀌는 지점이 명확해진다 | 감시 대상을 Nginx로 바꾸면 monitor.sh에서 정확히 몇 줄이 바뀌는가? 그 4개를 스크립트 상단 변수로 뽑아 두었는가, 아니면 코드 곳곳에 흩어 두었는가? |
| **운영 대응 (체크리스트 4절)** | — | **인시던트 대응의 단기/중기 분리.** 디스크가 차오를 때 "지금 당장 살리는 조치"(큰 파일 탐색, 로그 truncate, 임시 정리)와 "재발을 막는 조치"(로테이션 정책, 모니터링 임계값, 별도 파티션 분리)는 다른 작업이다 | 디스크 100%인 서버에 지금 접속했다면 첫 3개 명령은 무엇인가? `rm`으로 지웠는데 `df` 수치가 안 줄면 무엇을 의심하는가? 중기 대책으로 `/var/log`를 별도 파티션으로 빼면 무엇이 좋아지는가? |

---

### 0.9 자주 놓치는 함정

> 💡 아래는 조교가 정리한 오독 포인트다. 명세를 빠르게 읽으면 대부분 여기서 감점된다.

1. **`exit 1`과 `[WARNING]`을 섞는다.**
   R4-3(프로세스)·R4-4(포트)는 **실패 시 종료**, R4-5(방화벽 비활성)·R4-7(CPU/MEM/DISK 임계 초과)는 **경고만 출력하고 계속 진행**. 원문이 "스크립트는 종료하지 않는다"라고 못박았다. 방화벽이 꺼져 있다고 `exit 1` 하면 로그 한 줄도 안 남는다 — 요구사항 위반이다.

2. **권한 750인데 실행자를 owner로 착각한다.**
   `monitor.sh`의 owner는 **agent-dev**, 실행자는 **agent-admin**. agent-admin은 group 비트(`r-x`)로만 실행하므로 **agent-admin이 agent-core 그룹에 반드시 포함**되어야 한다(R4-2가 괄호로 명시). 또한 그룹을 추가한 뒤 재로그인하지 않으면 현재 세션에는 반영되지 않는다.

3. **cron은 로그인 셸 환경을 상속하지 않는다.**
   `~/.bashrc`에 `export AGENT_HOME=...`을 넣어두고 손으로는 잘 돌던 스크립트가, cron에서는 `$AGENT_HOME`이 빈 문자열이 되어 `/bin/monitor.sh`나 `//var/log/...` 같은 경로로 터진다. `PATH`도 최소라 `ss`·`ufw`(`/usr/sbin`)가 안 잡힐 수 있다. R5-2의 "1~2분 내 새 라인 누적" 확인이 이 함정을 잡아내는 장치다.

4. **`>` 와 `>>` 를 혼동한다.**
   로그는 **누적**이어야 한다(R4-8, 그리고 예시의 3줄 누적). `>`를 쓰면 매분 파일이 덮어써져 항상 1줄만 남고, "cron으로 로그가 증가하는가"라는 증거 항목(8번)을 만족할 수 없다. 평가 체크리스트 3절에 **명시적 질문으로 들어 있다.**

5. **`agent-core ONLY`를 "core가 읽을 수 있으면 된다"로 읽는다.**
   R2-5는 **agent-test는 접근 불가**라는 배타 조건이다. others 권한이 남아 있으면 미달이다. `api_keys`와 `/var/log/agent-app` **둘 다** 해당하며, 로그 디렉토리를 깜빡하고 `755`로 두는 경우가 흔하다.

6. **`0.0.0.0` 바인딩을 `127.0.0.1`로 처리한다.**
   R3-5는 `0.0.0.0:15034` LISTEN을 요구한다. 루프백 전용으로 뜨면 방화벽에 15034를 연 것도 무의미하고, `ss -tulnp` 증거도 요구와 다르게 찍힌다.

7. **방화벽에서 기존 22/tcp를 그대로 둔다.**
   R1-4는 "20022과 15034**만** 허용"이다. SSH 포트를 20022로 옮기면서 22 허용 규칙을 삭제하지 않으면 "만 허용" 조건 위반이다. 반대로 순서를 잘못 잡아 **자기 자신을 잠그는** 사고도 흔하니, 20022 허용 → sshd 변경/재시작 → 새 세션 접속 확인 → 22 제거 순서를 지킬 것.

8. **보너스 B2의 아카이브 경로를 잘못 적는다.**
   `/var/log/agent-app/archive/`가 아니라 **`/var/log/monitor/agent-app/archive/`** 다(원문 그대로). 그리고 B2(7일/30일, 시간 기반)는 필수인 R4-9(10MB/10개, 용량 기반)를 **대체하지 않는다.**

9. **제공 앱을 고치려 든다.**
   원문: "제공된 Python 앱은 '실행 대상'이며, 과제의 핵심은 관제/자동화 스크립트 구현이다." 앱 수정·재작성은 과제 범위가 아니다. 반대로 **자동화 스크립트를 Python으로 짜는 것은 명시적 금지 사항**이다.

10. **증거를 "설정 파일"로만 제출한다.**
    0.2의 체크리스트 8항목은 전부 "**확인 내역**"을 요구한다. `sshd_config` 내용뿐 아니라 `ss -tulnp`, `ufw status`, `id`, `ls -l`/`getfacl`, `crontab -l`, `tail -n 5 monitor.log`의 **실행 결과**가 있어야 한다. 특히 8번 항목은 **1분 간격 전/후 두 번의 로그 캡처**를 요구한다.

### 0.10 ✅ 과제 수행 점검 (명세 대조)

> 점검 방식: 저장소의 실제 소스를 명세의 요구사항 ID 와 1:1 대조. 판정 근거는 파일 경로로 명시.
> README·수행내역서의 "했다"는 서술이 아니라 `src/*.sh`, `verify_orbstack.sh` 의 코드를 직접 열어 근거를 잡았고,
> `monitor.sh` / `report.sh` / `archive_logs.sh` 는 저장소를 건드리지 않는 임시 디렉토리에서 **실제로 실행**해 확인했다(§ 실행 검증 기록).
>
> **근거 좌표 규칙** — `verify_orbstack.sh` 의 근거는 줄번호가 아니라 **함수 이름**(`v1_ssh()` 처럼)으로 적는다.
> 줄번호는 리팩터링에 견디지 못하는 좌표라, 코드가 한 블록만 움직여도 문서의 근거가 조용히 거짓이 된다.
> (실제로 2026-09-19 에 이 「0. 과제 명세」 절을 README 앞에 끼워 넣었을 때 같은 일이 났다.)
> 줄번호를 유지한 `src/*.sh` 는 이번 수정에서 해당 참조 구간이 밀리지 않도록 변경을 그 뒤에 배치했다.

**종합 판정: 충족** — 필수 30개 중 충족 27 / 부분 0 / 미충족 0 / 로컬검증불가 3

> 2026-09-21 보완으로 기존 🟡 2건(R1-4 방화벽 배타성, 보너스 B2-2 아카이브 디렉토리)이 해소됐다.
> 상세는 아래 「🔧 2026-09-21 보완 내역」 참조.

| ID | 요구사항 (요약) | 판정 | 근거 / 비고 |
| --- | --- | --- | --- |
| R1 | 기본 보안 및 네트워크 설정 | ✅ 충족 | 하위 R1-1~R1-4 전부 충족. R1-4 의 배타성은 2026-09-21 에 보완 |
| R1-1 | SSH 포트 20022 | ✅ 충족 | `src/01_ssh_hardening.sh:32-35` — `sed -i -E 's/^#?Port .*/Port 20022/'`, 재시작은 `:37-42`. 검증 `:47-48`, 자동 단언 `verify_orbstack.sh` `v1_ssh()`. ⚠ Ubuntu 의 `/etc/ssh/sshd_config.d/*.conf` Include 드롭인은 치환 대상이 아님(드롭인에 Port 가 있으면 무력화) |
| R1-2 | Root 원격 로그인 차단 | ✅ 충족 | `src/01_ssh_hardening.sh:34` — `s/^#?PermitRootLogin .*/PermitRootLogin no/`. 자동 단언 `verify_orbstack.sh` `v1_ssh()` |
| R1-3 | UFW/firewalld 중 택1 활성화 | ✅ 충족 | `src/02_firewall_allowlist.sh:36` (`ufw --force enable`), `:39` (`systemctl enable --now ufw`). 자동 단언 `verify_orbstack.sh` `v2_ufw()` |
| R1-4 | 인바운드 20022/tcp · 15034/tcp **만** 허용 | ✅ 충족 | `src/02_firewall_allowlist.sh:27-33` — `default deny incoming` + 2개 allow. 여기에 2026-09-21 보완으로 ① 같은 파일의 "20022/15034 이외의 인바운드 허용 규칙 제거" 단계(`ufw status numbered` 를 **큰 번호부터** `ufw --force delete`)가 붙어 기존 `22/tcp`·`OpenSSH` 프로파일·`ufw limit` 잔재가 남아 있어도 실제로 제거되고, ② 같은 파일 끝의 배타성 검증 + `verify_orbstack.sh` `v2_ufw()` 가 **"20022/15034 가 아닌 `ALLOW IN`·`LIMIT IN` 라인이 0개"** 를 단언하며 `Default: deny (incoming)` 까지 확인한다. 머신 재사용이 기본 동작(`verify_orbstack.sh` 헤더 주석의 사용법)이라도 위반이 통과하지 않는다 |
| R2 | 계정/그룹/권한 체계 | ✅ 충족 | 하위 R2-1~R2-5 전부 충족 |
| R2-1 | 계정 3개 (admin/dev/test) | ✅ 충족 | `src/03_users_and_groups.sh:27-34` — `useradd -m -s /bin/bash` 루프, 존재 시 skip |
| R2-2 | 그룹 2개 + 멤버 구성 | ✅ 충족 | `src/03_users_and_groups.sh:24-25`(groupadd), `:37-43` — common=admin/dev/test, core=admin/dev (test 제외). 자동 단언 `verify_orbstack.sh` `v3_users()` 는 `agent-test` 가 core 에 **없음**까지 검사 |
| R2-3 | 디렉토리 4종 생성 | ✅ 충족 | `src/04_directories_and_acl.sh:28-33` — `$AGENT_HOME`, `upload_files`, `api_keys`, `/var/log/agent-app` (+ `bin`) |
| R2-4 | upload_files = agent-common R/W | ✅ 충족 | `src/04_directories_and_acl.sh:36`(chown `:agent-common`), `:42`(770), `:48-49`(`setfacl -m/-dm g:agent-common:rwx`) |
| R2-5 | api_keys · /var/log/agent-app = agent-core ONLY | ✅ 충족 | `src/04_directories_and_acl.sh:37-38`(chgrp agent-core / chown root:agent-core), `:43-44`(770 → others `---` = agent-test 접근 불가), `:52-57`(ACL + default 상속). getfacl 캡처 `docs/md/요구사항_수행_내역서.md:648-676` 에 `other::---` 확인 |
| R3 | 앱 실행 환경 구성 | ✅ 충족 | 하위 R3-1~R3-3 충족, R3-4·R3-5 는 런타임 관측(아래) |
| R3-1 | 환경변수 5종 | ✅ 충족 | `src/05_env_and_keyfile.sh:25-33` — agent-admin `~/.bashrc` 에 AGENT_HOME/PORT/UPLOAD_DIR/KEY_PATH/LOG_DIR 5줄 영구 등록 |
| R3-2 | `api_keys/t_secret.key` = `agent_api_key_test` 1줄 | ✅ 충족 | `src/05_env_and_keyfile.sh:39` — `echo "agent_api_key_test" \| tee`(정확히 1줄), `:42-43` 소유 agent-admin:agent-core / 640 |
| R3-3 | 일반 계정 실행(root 금지) | ✅ 충족 | `verify_orbstack.sh` `s5_app_run()` — `sudo -u agent-admin env ... ./agent-app`, `src/00_run_all.sh:49-50` 안내도 `sudo -iu agent-admin` |
| R3-4 | Boot Sequence 5/5 `[OK]` + `Agent READY` | ⬜ 로컬 검증 불가 | 실행에 Ubuntu 24.04 + 제공 바이너리 필요(`bin/agent-app`, 7.9MB). **증거는 있음**: 자동 단언 `verify_orbstack.sh` `v5_app()`(1~5 각 단계 `[OK]` + `Agent READY` grep), 콘솔 캡처 `docs/md/요구사항_수행_내역서.md:831-843`. 다만 캡처가 각 단계의 `... ` 상세줄과 `All Boot Checks Passed!` 줄을 생략한 축약본이고, `.verify-artifacts/agent.out` 은 저장소에 커밋돼 있지 않다 → **증거 충분성: 대체로 충분** |
| R3-5 | `0.0.0.0:15034` LISTEN | ⬜ 로컬 검증 불가 | 증거: `verify_orbstack.sh` `v5_app()`, 캡처 `docs/md/요구사항_수행_내역서.md:854-855`. 그러나 ① 자동 검증이 `$4 ~ /:15034$/` 만 보므로 **`127.0.0.1:15034` 여도 통과**한다(명세가 구분을 요구한 지점), ② 캡처의 PID 가 `pid=XXXX` 플레이스홀더, ③ `요구사항_수행_내역서.md:1082` 체크리스트는 `python3` 프로세스 표시라 적었으나 실제 프로세스명은 `agent-app` → **증거 충분성: 부분 미흡** |
| R4 | monitor.sh 구현 | ✅ 충족 | 9개 하위 요구 전부 충족, 7개는 실제 실행으로 확인 |
| R4-1 | `$AGENT_HOME/bin/monitor.sh` / agent-dev:agent-core / 750 | ✅ 충족 | `src/06_deploy_app_and_scripts.sh:49-50` — `install -m 0750 -o agent-dev -g agent-core`. `verify_orbstack.sh` `s5_app_setup()` 은 이 배포 명령을 베껴 쓰지 않고 **`src/06` 을 그대로 실행**한다(2026-09-21 보완) |
| R4-2 | cron 실행자 agent-admin (agent-core 포함) | ✅ 충족 | `src/07_cron_schedule.sh:23-28`(`sudo -u agent-admin ... crontab -`) + `src/03_users_and_groups.sh:42`(admin 을 agent-core 에 추가) → 750 의 group `r-x` 로 실행 가능 |
| R4-3 | 프로세스 확인, 비정상 시 `exit 1` | ✅ 충족 | `src/monitor.sh:39-45` — `pgrep -x agent-app`, 실패 시 `[ERROR]` 후 `exit 1`. **실행 확인**: 앱 미기동 상태에서 `[FAIL]` + exit=1 재현. `-x`(comm 완전일치)를 써서 `-f` 의 자기참조 오탐을 회피한 점은 명세 해설이 지적한 함정을 제대로 피한 것 |
| R4-4 | TCP 15034 LISTEN 확인, 비정상 시 `exit 1` | ✅ 충족 | `src/monitor.sh:47-57` — `ss -tlnH` (없으면 netstat 폴백) + `exit 1`. **실행 확인**: 15034 리스너를 띄운 상태에서 `Checking port 15034... [OK]` |
| R4-5 | 방화벽 비활성 시 `[WARNING]` 만, 종료 금지 | ✅ 충족 | `src/monitor.sh:64-80` — WARNING 출력 후 계속 진행. **실행 확인**: 방화벽 없는 환경에서 `[WARNING] Firewall is not active.` 출력 후 끝까지 진행하고 `exit=0`. sudo 없이 판별되도록 systemd/`/etc/ufw/ufw.conf`/firewalld 3중 폴백(`:71-77`) |
| R4-6 | CPU/MEM/DISK(root, Used%) 수집 | ✅ 충족 | `src/monitor.sh:86`(top idle 기반), `:91`(`free` used/total), `:95`(`df -P /` 5열). **실행 확인**: `free`/`df` 원값과 스크립트 출력이 일치(MEM 31.6%, DISK 35%). 2026-09-21 보완으로 CPU 는 `top -bn2 -d 1` 의 **두 번째 샘플**을 쓴다 — 1회 샘플(`-bn1`)이 부팅 이후 누적 평균에 가깝다는 명세 해설의 지적을 해소. 비용은 실행당 약 1초 |
| R4-7 | CPU>20 / MEM>10 / DISK>80 초과 시 `[WARNING]`, 종료 금지 | ✅ 충족 | `src/monitor.sh:18-20`(임계값 20/10/80), `:107-112`(awk 부동소수 비교 → echo). **실행 확인**: MEM 31.6% 에서 `[WARNING] MEM threshold exceeded (31.6% > 10%)` 출력 후 정상 종료(exit=0) |
| R4-8 | `/var/log/agent-app/monitor.log` 지정 포맷 누적 | ✅ 충족 | `src/monitor.sh:126-127` — `[${TS}] PID:.. CPU:..% MEM:..% DISK_USED:..%` 를 `>>` 로 append. **실행 확인**: `[2026-09-19 13:24:57] PID:4066568 CPU:3.0% MEM:31.6% DISK_USED:35%` — 명세 포맷과 문자 단위로 일치 |
| R4-9 | 최대 10MB / 10개 파일 유지 | ✅ 충족 | `src/monitor.sh:23-24, 135-146` — 10MB 초과 시 `.10` 삭제 → `.N→.N+1` 시프트 → `.1` 로 회전. **실행 확인**: 11MB 로그로 실행 시 `monitor.log.1` 생성 + 현재 로그 0바이트 재시작. (보관 파일은 현재 로그 + 회전본 10개 = 11개 ≈ 최대 110MB 로 읽히나, 원문 "10개 파일 유지" 해석 범위 내) |
| R5 | 자동 실행(cron) | ✅ 충족 | 하위 R5-1 충족, R5-2 는 런타임 관측 |
| R5-1 | agent-admin crontab, 매분 실행 | ✅ 충족 | `src/07_cron_schedule.sh:25` — `* * * * * AGENT_HOME=... AGENT_PORT=... AGENT_LOG_DIR=... /home/agent-admin/agent-app/bin/monitor.sh >> ... 2>&1`. cron 이 `.bashrc` 를 상속하지 않는 함정을 **명령줄 인라인 변수**로 정면 해결. 중복 등록 방지 `:24` |
| R5-2 | 등록 후 1~2분 내 로그 자동 누적 확인 | ⬜ 로컬 검증 불가 | cron 데몬 + 실제 머신 필요. **증거는 있음**: `verify_orbstack.sh` `v7_cron_wait()` 가 before 라인수 → 70초 대기 → after 비교로 자동 단언(`die "log lines did not grow"`), 문서 캡처 `docs/md/요구사항_수행_내역서.md:1006-1015` 에 `wc -l` 2→4 및 1분 간격 3라인 → **증거 충분성: 충분** |

#### 보너스 과제

| ID | 요구사항 (요약) | 판정 | 근거 / 비고 |
| --- | --- | --- | --- |
| B1 | report.sh 요약 리포트 | ✅ 충족 | `src/report.sh` 전체(74줄), 순수 awk 구현 — 외부 언어 미사용 |
| B1-1 | CPU/MEM/DISK 평균·최대·최소 + 샘플 수 콘솔 출력 | ✅ 충족 | `src/report.sh:44-51`(집계), `:59-72`(출력). **실행 확인**: 명세 예시 로그 3줄 투입 → CPU avg 18.1 / max 25.3 at 14:00:01 / min 10.2, Data Points: 3. 명세 예시엔 없는 `[Disk]` 블록까지 출력(요구는 DISK 포함이므로 오히려 정확) |
| B1-2 | 시작/종료 시간 인자로 구간 분석 | ✅ 충족 | `src/report.sh:11-12, 34-35` — 문자열 비교 기반 구간 필터(고정폭 타임스탬프라 사전식=시간순). **실행 확인**: `"2026-02-25 13:58:30" "2026-02-25 14:00:00"` → 1 sample 만 집계. 샘플 0개 시 `[INFO] No samples in the given range.` + exit 0 (`:55-58`) |
| B2 | 시간 기반 로그 보존 정책 | ✅ 충족 | 로직 + 아카이브 디렉토리 준비 단계 모두 존재 (2026-09-21 보완) |
| B2-1 | 7일 경과 `*.log` 압축 | ✅ 충족 | `src/archive_logs.sh:29-39` — `find -maxdepth 1 -type f -name '*.log' -mtime +7 -print0` + `while read -d ''`(공백/특수문자 안전). **실행 확인**: mtime 10일 파일만 압축, 1일 파일은 보존 |
| B2-2 | 아카이브 이동 → `/var/log/monitor/agent-app/archive/` | ✅ 충족 | 경로 자체는 원문과 정확히 일치(`src/archive_logs.sh:11`)하고 gzip 후 원본 삭제로 "이동"을 구현(`:32-35`). 2026-09-21 보완으로 `src/04_directories_and_acl.sh` 끝의 「보너스 2: 로그 아카이브 디렉토리」 블록이 `mkdir -p` + `chown root:agent-core` + `chmod 770` + `setfacl -m/-dm g:agent-core:rwx` 로 디렉토리를 **setup 단계에서 미리** 만든다. 같은 블록의 검증이 `sudo -u agent-admin test -w` 로 **cron 실행자가 실제로 쓸 수 있는지**까지 확인하고, `verify_orbstack.sh` `v4_acl()` 도 같은 단언을 반복한다. → `src/07_cron_schedule.sh:26` 의 매일 03:10 작업이 더 이상 `[ERROR] Cannot create archive directory` 로 죽지 않는다 |
| B2-3 | 30일 경과 `*.gz` 삭제 | ✅ 충족 | `src/archive_logs.sh:43-45` — `find ... -name '*.gz' -mtime +30 -print0`. **실행 확인**: mtime 40일 .gz 1개 삭제(`deleted=1`) |
| B2-4 | 예외 처리(디렉토리 미존재/권한 부족/대상 0개) | ✅ 충족 | `src/archive_logs.sh:14-25`(소스 미존재 → WARNING + exit 0, 아카이브 생성 실패/쓰기 불가 → ERROR + exit 1), `:33-38`(압축 실패 개별 WARNING). **실행 확인**: 3개 경로 모두 재현, 대상 0개일 때 `compressed=0, deleted=0` 으로 안전 종료 |

#### 🔍 발견된 격차와 보완 제안

1. ~~**[중요] B2-2 — 아카이브 디렉토리가 cron 실행 계정으로는 만들어지지 않는다.**~~ → **2026-09-21 해결.**
   `archive_logs.sh` 는 `/var/log/monitor/agent-app/archive` 를 스스로 `mkdir -p` 하려 하지만, 등록된 실행자는 agent-admin 이고 `/var/log` 는 root 소유라 매번 exit 1 로 죽었다(실행으로 재현했었다).
   → 조치: `src/04_directories_and_acl.sh` 끝에 「보너스 2: 로그 아카이브 디렉토리」 블록(`mkdir -p` + `chown root:agent-core` + `chmod 770` + `setfacl -m/-dm`)을 추가하고, 같은 파일의 검증과 `verify_orbstack.sh` `v4_acl()` 양쪽에서 `sudo -u agent-admin test -w` 로 **cron 실행자의 쓰기 가능 여부**를 단언하게 했다. 디렉토리를 *만드는* 일은 sudo 가 있는 setup 의 몫, cron 은 *쓰기만* 하면 된다는 경계를 코드로 고정한 것.
   (남은 선택지: `ARCHIVE_DIR="${AGENT_ARCHIVE_DIR:-/var/log/monitor/agent-app/archive}"` 로 외부 주입 가능하게 하면 테스트가 더 쉬워진다 — 미적용.)

2. ~~**[중요] R1-4 — "만 허용"의 배타성이 보장·검증되지 않는다.**~~ → **2026-09-21 해결.**
   `02_firewall_allowlist.sh` 는 규칙을 추가만 하고 기존 규칙(예: 이전 실습의 `22/tcp`, `OpenSSH` 앱 프로파일)을 제거하지 않았고, `verify_orbstack.sh` 의 `v2_ufw()` 도 두 규칙의 존재만 확인하면서 `only ... allowed` 라고 단언했다. 머신 재사용이 기본 동작이므로 22 가 열린 채 "통과" 할 수 있었다.
   → 조치: ① `ufw --force enable` 이후 `ufw status numbered` 를 파싱해 20022/15034 가 아닌 인바운드 허용 규칙(`ALLOW IN` **및** `LIMIT IN`)을 **큰 번호부터** `ufw --force delete` (ufw 가 삭제할 때마다 뒤 번호를 당겨오기 때문), ② 같은 파일의 검증 블록과 `v2_ufw()` 를 **"20022/15034 가 아닌 `ALLOW IN`·`LIMIT IN` 라인이 0개"** 라는 배타 검사로 교체하고 `Default: deny (incoming)` 확인을 추가, ③ 안전 순서는 실행 순서로 보장된다 — `00_run_all.sh` 가 01(sshd → 20022) → 02(방화벽) 순서로 돌고 20022 허용이 삭제보다 먼저이므로 자기 자신을 잠그지 않는다. 이 전제를 스크립트 주석에 명시했다.
   > 고정 개수(`== 4`)가 아니라 "예외가 0건"으로 쓴 이유: IPv6 비활성 머신에서는 인바운드 허용이 2줄이라 개수 비교는 환경에 따라 거짓 실패를 낸다. 검사해야 할 사실은 개수가 아니라 **예외의 부재**다.
   > `LIMIT IN` 까지 보는 이유: `ufw limit 22/tcp` 는 SSH brute-force 방어로 흔히 쓰이는 레시피인데, 그 규칙도 22 번 인바운드를 **허용**한다. `ALLOW` 만 검사하면 22 가 열린 채 R1-4 가 ✅ 로 찍힌다(2026-09-21 검수에서 모의 출력으로 재현해 보강).

3. **[경미] R3-5 — `0.0.0.0` 바인딩을 실제로 구분하지 않는다.**
   `verify_orbstack.sh` `v5_app()` 의 `$4 ~ /:15034$/` 는 `127.0.0.1:15034` 도 통과시킨다. 명세가 루프백과 구분하라고 못박은 항목이라 검증이 요구를 못 따라간다. 문서 캡처(`요구사항_수행_내역서.md:855`)의 PID 는 `pid=XXXX` 플레이스홀더라 증거로서도 반쪽이다.
   → 보완: `awk '$4 ~ /^(0\.0\.0\.0|\*):15034$/'` 로 바꾸고, `ss -tlnp` 실제 출력(PID 포함)을 그대로 붙여넣기. 같은 문서 `:1082` 의 "`python3` 프로세스 표시" 문구도 실제 프로세스명 `agent-app` 로 정정 필요.

4. **[경미] 필수 증거 자료 체크리스트가 "체크되지 않은 채" 제출 상태다.**
   `docs/md/요구사항_수행_내역서.md:1075-1087` 의 11개 항목이 전부 `- [ ]` 이고, §1.3 제목은 "(스크린샷/출력 첨부 **위치**)", §2 는 "검증 출력 **예**"(`:294`)라 어디까지가 실제 캡처인지 독자가 구분할 수 없다. `verify_orbstack.sh` `collect_evidence()` 가 `evidence.txt` 를 만들지만 `.verify-artifacts/` 는 저장소에 없다.
   → 보완: 한 번 실행해 나온 `.verify-artifacts/evidence.txt` + `agent.out` 을 저장소에 커밋(또는 문서에 통째로 인라인)하고, 캡처 블록마다 "예시"인지 "실제 출력"인지 라벨을 달고 체크박스를 채울 것. 특히 8번 항목은 1분 간격 before/after 2회 캡처가 요구되므로 `wc -l` 2회 출력을 시각과 함께 남겨야 한다.

5. **[경미] README 가 실제 저장소 상태와 어긋난다.**
   `## 2. 디렉토리 구조` 의 마지막 줄이 `.github/workflows/verify.yml` 을 명시하지만 해당 파일은 없다(커밋 `20c859d chore: verify.yml 삭제.` 로 제거됨). 또 `## 3. 최종 산출물` 과 `## 3. 기능 요구 사항` 이 같은 절 번호 "3" 을 쓴다. 그리고 README 최상단에 **과제 원문 명세 절이 없어** 무엇을 요구받았는지가 저장소만 보고는 확정되지 않는다.
   → 보완: 삭제된 워크플로 줄 제거, 절 번호 재정렬, 그리고 `0. 과제 명세` 절(원문 요구사항 + 학습 포인트)을 README 최상단에 추가.

6. ~~**[경미] R4-6 CPU 측정 정확도.**~~ → **2026-09-21 해결.**
   `src/monitor.sh:86` 의 `top -bn1` 1회 샘플은 부팅 이후 누적 평균에 가까워 순간 사용률로는 부정확했다(명세 해설이 명시적으로 지적한 지점).
   → 조치: `top -bn2 -d 1` 로 1초 간격 2샘플을 뜨고 awk 가 **두 번째 `Cpu(s)` 라인만** 채택한다(`END {print v}`). 줄 수는 그대로라 이 표의 `:86` 좌표도 유효하다. 대가는 실행당 약 1초이며 매분 1회 cron 에서는 허용 범위 — 그 판단 근거를 코드 주석에 남겼다.

7. ~~**[치명] 검증 하네스가 산출물이 아니라 손으로 베낀 사본을 실행했다.**~~ → **2026-09-21 해결.**
   `verify_orbstack.sh` 의 `s1_ssh()`~`s7_cron_setup()` 이 `src/01`~`src/07` 과 **같은 뜻의 명령을 다시 적어** 실행하고 있었다. 결과적으로 이 하네스는 `src/` 를 검증하지 않았다 — `src/01~07` 을 통째로 지워도 `ALL CHECKS PASSED` 가 찍혔다. 그리고 두 사본이 갈라지면(예: `src/07` 은 cron 항목을 2개 등록하는데 하네스 사본은 1개만 등록했다) 어느 쪽이 진실인지 알 수 없다.
   → 조치: 각 setup 함수의 본문을 `run_src NN_*.sh` 한 줄로 바꿔 **`src/` 의 산출물을 그대로 실행**하게 했다. 실행 대상은 `REQUIRED_SOURCES` 배열 한 곳에 모았고, `preflight()` 가 그 목록을 그대로 존재 검사에 쓴다(같은 사실을 두 곳에 두지 않기 위해). 검사 순서도 뒤집어 산출물 확인이 `orb` CLI 확인보다 **먼저** 오게 했다 — 그래야 파일 누락이 "orb 없음" 뒤에 숨지 않는다.
   → **깨뜨려 확인함**: `src/01_ssh_hardening.sh` 를 지우고 실행하면 `✗ missing artifact: .../src/01_ssh_hardening.sh` 로 즉시 빨간 불(exit 1). 되돌리면 `✓ 11 source artifacts exist`. (§ 실행 검증 기록 #13)

#### 🔧 2026-09-21 보완 내역

| # | 무엇을 | 어디를 | 왜 |
| --- | --- | --- | --- |
| 1 | 하네스가 산출물을 **실제로 실행** | `verify_orbstack.sh` `REQUIRED_SOURCES` / `run_src()` / `preflight()` / `s1_ssh()`~`s7_cron_setup()` | 규칙은 문서가 아니라 검사에 살아야 한다. 사본을 채점하는 검사는 검사가 아니다 |
| 2 | 아카이브 디렉토리 **setup 단계에서 생성** | `src/04_directories_and_acl.sh` 「보너스 2」 블록, `verify_orbstack.sh` `v4_acl()` | 보너스 2 가 매일 03:10 에 조용히 죽고 있었다(실제 버그) |
| 3 | 방화벽 "만 허용"의 **배타성 확보 + 배타 검사** | `src/02_firewall_allowlist.sh` 삭제 단계·검증 블록, `verify_orbstack.sh` `v2_ufw()` | 규칙을 더하는 것으로는 배타성이 생기지 않는다. 남은 것을 지워야 생긴다 |
| 3-b | 배타 검사 범위를 `ALLOW IN` → **`ALLOW IN`·`LIMIT IN`** 으로 | 같은 두 곳 | 검수(#22)에서 구멍이 나왔다. `ufw limit 22/tcp` 도 22 번 인바운드를 허용하는데 `ALLOW` 만 보면 통과했다 — 검사가 요구보다 좁으면 그 검사는 없는 것과 같다 |
| 4 | CPU 측정을 **2회 샘플의 두 번째**로 | `src/monitor.sh:85-86` | 1회 샘플은 '지금'이 아니라 부팅 이후 평균이다 |
| 5 | 근거 좌표를 **줄번호 → 함수 이름**으로 | 이 절(0.10)의 `verify_orbstack.sh` 참조 전부 | 줄번호는 리팩터링에 견디지 못한다. 1번 작업으로 이 파일이 크게 움직였고, 같은 일이 또 일어나도 문서가 거짓이 되지 않게 했다 |

> 하지 않은 것: `verify_orbstack.sh` `v5_app()` 의 `0.0.0.0` 바인딩 구분(격차 3), 증거 파일 커밋(격차 4), README 절 번호 재정렬(격차 5). 이번 작업 범위 밖이라 그대로 뒀다.

#### 🧪 실행 검증 기록

#1~#12 (2026-09-19, 점검 시점) 은 모두 **저장소를 수정하지 않고** 임시 디렉토리(`scratchpad/t`, `scratchpad/arch`)에서 수행했다. `git status --porcelain` 결과 없음(저장소 무변경) 확인.
#13~#19 (2026-09-21, 보완 시점) 은 위 「🔧 2026-09-21 보완 내역」 을 적용한 **뒤** 같은 절차를 다시 돌린 결과다 — 수정 전/후를 같은 검증으로 비교했고 #1~#10 의 결과는 변하지 않았다.
양쪽 모두 패키지 설치·네트워크 접근 없음.
#20~#22 (2026-09-21, **검수 시점**) 는 보완분을 적대적으로 재검증한 결과다 — 보완 에이전트의 보고를 믿지 않고 같은 명령을 직접 다시 돌렸고, 그 과정에서 찾은 결함 1건(`LIMIT IN`)을 고친 뒤의 결과다.

| # | 명령 | 결과 |
| --- | --- | --- |
| 1 | `bash -n` (src/*.sh, demo.sh, verify_orbstack.sh 13개 전부) | 전부 OK — 문법 오류 없음 |
| 2 | `AGENT_LOG_DIR=<tmp> bash src/monitor.sh` (앱 미기동) | `Checking process 'agent-app'... [FAIL]` + `[ERROR] Application process not running.` → **exit 1** (R4-3) |
| 3 | 더미 프로세스(`agent-app` 이름) + 15034 리스너 기동 후 동일 실행 | `[OK] (PID: 4066568)` / `Checking port 15034... [OK]` / `[WARNING] Firewall is not active.` / `CPU 3.0% MEM 31.6% DISK 35%` / `[WARNING] MEM threshold exceeded (31.6% > 10%)` → **exit 0** (R4-4·R4-5·R4-6·R4-7 동시 확인: 경고는 종료를 유발하지 않음) |
| 4 | 위 실행 후 로그 라인 확인 | `[2026-09-19 13:24:57] PID:4066568 CPU:3.0% MEM:31.6% DISK_USED:35%` — 명세 포맷과 일치, `>>` 누적 (R4-8) |
| 5 | `truncate -s 11M monitor.log` 후 재실행 | `monitor.log.1`(11.5MB) 생성 + `monitor.log` 0바이트로 재시작, 다음 실행은 67바이트 정상 append (R4-9) |
| 6 | `AGENT_LOG_DIR=<tmp> bash src/report.sh` (명세 예시 로그 3줄) | CPU avg 18.1 / max 25.3 at 2026-02-25 14:00:01 / min 10.2, MEM·DISK 동일, `Data Points: 3 samples` (B1-1) |
| 7 | `bash src/report.sh "2026-02-25 13:58:30" "2026-02-25 14:00:00"` | 1 sample 만 집계 → 구간 필터 동작 (B1-2). 빈 구간은 `[INFO] No samples in the given range.` + exit 0 |
| 8 | `bash src/archive_logs.sh` (원본, AGENT_LOG_DIR 만 임시 지정) | `[ERROR] Cannot create archive directory: /var/log/monitor/agent-app/archive` + **exit 1** — B2-2 격차 재현 |
| 9 | `AGENT_LOG_DIR=/nonexistent bash src/archive_logs.sh` | `[WARNING] Source log directory not found` + exit 0 — 안전 종료 (B2-4) |
| 10 | ARCHIVE_DIR 만 임시 경로로 바꾼 **사본**으로 실행(원본 무변경) | mtime 10일 `old.log` 만 `old.log.20260919_132522.gz` 로 압축·이동, 1일 파일 보존 → `compressed=1`; 이어서 40일 지난 .gz 삭제 → `deleted=1` (B2-1·B2-3) |
| 11 | `grep -rn "python\|\.py" src/ demo.sh verify_orbstack.sh` | 자동화 스크립트 안에서 Python 호출 **없음**. 유일한 히트는 `verify_orbstack.sh` `install_base()` 의 `apt-get install ... python3`(패키지 설치). `tools/*.py` 5개는 문서 빌드·바이너리 정적 분석 학습용이며 미션 요구(monitor/report/archive) 구현에 관여하지 않음 → **"Bash로만" 제약 위반 없음** |
| 12 | `find` 로 `.github` 확인 | 존재하지 않음 — README 구조도(`## 2. 디렉토리 구조` 의 `.github/workflows/verify.yml` 줄)와 불일치 |
| 13 | **축4 재현·수정 확인** — `src/01_ssh_hardening.sh` 삭제 후 `bash verify_orbstack.sh` | 수정 전: `✗ orb CLI not found` 만 나오고 파일 누락을 **감지 못함**. 수정 후: `✗ missing artifact: .../src/01_ssh_hardening.sh` + exit 1. 원복 후 `✓ 11 source artifacts exist` 로 복귀 |
| 14 | `run_src()` 인자 전개 단위 확인 (`msh` 를 echo 로 치환) | `run_src 01_ssh_hardening.sh` → `bash '<repo>/src/01_ssh_hardening.sh'`, `run_src 06_… "SOURCE_DIR='/tmp/b1-1-stage'"` → `SOURCE_DIR='/tmp/b1-1-stage' bash '<repo>/src/06_deploy_app_and_scripts.sh'` |
| 15 | 배타 검사 단위 확인 — `ufw status verbose` 모의 출력 5종 | 정상(v4/v6 4줄) → OK / `22/tcp` 잔존 → **VIOLATION** / `OpenSSH` 프로파일 → **VIOLATION** / 서브넷 `Anywhere ALLOW IN 192.168.1.0/24` → **VIOLATION** / `ALLOW OUT` 만 추가 → OK(인바운드 아님) |
| 16 | 삭제 대상 추출 단위 확인 — `ufw status numbered` 모의 출력(11줄, v6·2자리 번호 혼재) | `11 10 9 6 2 1` 을 **내림차순**으로 추출(= 큰 번호부터 삭제). 이미 깨끗한 경우·`Status: inactive` 인 경우 모두 빈 결과 |
| 17 | `top -bn2 -d 1` CPU 샘플링 | `Cpu(s)` 라인 2개 확인, 두 번째 값만 채택됨. 소요 약 1.2초 |
| 18 | 수정 후 `bash -n` 13개 + monitor/report/archive 재실행 | 전부 수정 전과 동일 — 문법 오류 0, `monitor.sh` 로그 라인 포맷 일치, `report.sh` 집계값 동일(CPU avg 18.1 / Data Points 3), `archive_logs.sh` 예외 처리 동일 |
| 19 | `ARCHIVE_DIR` 만 임시 경로로 바꾼 **사본**으로 `archive_logs.sh` 재실행 (원본 무변경) | 디렉토리가 존재하고 쓰기 가능하면 `compressed=1, deleted=1` + exit 0 — B2 의 유일한 결함이 스크립트 로직이 아니라 **디렉토리 준비 단계 부재**였음을 다시 확인. `/var/log/monitor/...` 의 실제 생성은 root 권한 + 실제 머신이 필요하므로 이 환경에서는 실행하지 않았고, `src/04` 의 코드와 `verify_orbstack.sh` `v4_acl()` 의 단언(`sudo -u agent-admin test -w`)으로 갈음한다. 그래서 위 #8/#9 (원본 경로 그대로) 는 이 환경에서 여전히 같은 에러를 재현한다 |
| 20 | **검수 재현** — `bash -n` 13개 + `demo.sh` 드라이런 + `bash verify_orbstack.sh` | 문법 오류 0/13. `demo.sh` 는 Linux 호스트라 `⚠ 이 스크립트는 macOS 전용이다` 로 exit 1(설계대로). `verify_orbstack.sh` 는 `✓ 11 source artifacts exist` → `✗ orb CLI not found` exit 1. `src/01_ssh_hardening.sh` 를 지운 사본에서는 `✗ missing artifact: …/src/01_ssh_hardening.sh` — #13 재현됨 |
| 21 | **검수 재현** — monitor/report/archive 실행 + `0.10` 표의 `파일:줄번호` 근거 대조 | `monitor.sh` 앱 미기동 → exit 1 / 정상 → `CPU 11.8% MEM 33.8% DISK 32%` + 포맷 일치 + exit 0(소요 1.3초). 11MB 로그 → `monitor.log.1` 회전. `report.sh` → CPU avg 18.1 / Data Points 3, 구간 필터 1건. `archive_logs.sh` → 사본에서 `compressed=1, deleted=1`. `src/*.sh` 줄번호 근거 **41건 전수** 및 `docs/*.md` 근거 7건을 열어 대조 — 어긋남 0건. `v1_ssh()`~`collect_evidence()` 함수 좌표 14개 전부 실재 |
| 22 | **검수에서 찾은 결함** — `ufw limit 22/tcp` 모의 출력 투입 | 수정 전: 삭제 대상 0건 + 배타 검사 위반 0건 → **22 번이 열린 채 R1-4 가 통과**. `LIMIT IN` 을 패턴에 추가한 뒤 모의 12종(정상·주석·v6·`OpenSSH`·서브넷·`ALLOW OUT`·`LIMIT OUT`·`DENY IN`·inactive 포함) 재실행 → 삭제 대상 `9 7 6 2 1`, 위반 탐지 4/4, 거짓 양성 0 |

**미실행 항목**: SSH(20022/PermitRootLogin) 실제 적용, UFW 실제 활성/규칙 및 22/tcp 제거, 계정·그룹·ACL 실제 생성, `/var/log/monitor/.../archive` 실제 생성, `agent-app` 바이너리 Boot Sequence, cron 실제 누적. 모두 root 권한 + Ubuntu 24.04 머신(OrbStack) + 네트워크 설치가 필요해 이 환경에서는 실행하지 않았고, 대신 스크립트 코드와 `verify_orbstack.sh` 의 자동 단언, 수행내역서의 캡처를 증거로 판정했다.
그래서 2026-09-21 보완분도 **머신이 필요한 부분(§1~§7 실제 적용)은 코드와 단언까지**, **머신 없이 돌려볼 수 있는 부분(하네스 preflight, 파싱 로직, CPU 샘플링, monitor/report/archive 재실행)은 실제 실행까지** 확인했다 — 어디까지가 관측이고 어디부터가 코드 근거인지 구분해 둔다.

---

## 1. 미션 개요

서버 장애가 났을 때 로그가 없으면 원인 분석은 '감'에 의존하게 된다. 단순히 리눅스 명령어를 암기하는 게 아니라, **권한 관리 → 네트워크 보안 → 리소스 관제 → 로그 자동화** 까지 서버 운영자 시점에서 직접 설계해 본다.

학습 목표 (수료 후 스스로 설명할 수 있어야 한다):

- SSH 포트 변경과 root 원격 접속 차단이 왜 기본 보안에 해당하는가
- "필요 포트만 허용"하는 방화벽 정책을 구성·검증하는 방법
- 역할 기반 계정/그룹과 ACL로 공유/보안 디렉토리를 분리하는 이유
- 환경 변수로 실행 환경을 고정하는 이유와 검증 방법
- 쉘 스크립트로 프로세스/포트/리소스 상태를 수집·로깅해 운영 문제를 추적하는 흐름
- crontab 주기 실행과 로그 보존 정책(압축/삭제)이 왜 필요한가

---

## 2. 디렉토리 구조

```
codyssey_B1-1/
├── README.md                       ← 이 파일 (루트 유지)
│
├── docs/
│   ├── md/                                ← 원본 .md 문서들
│   │   ├── 요구사항_수행_내역서.md       ← 제출용 문서 (필수)
│   │   ├── 문제_설명.md                  ← 평가문항 답변 정리
│   │   ├── 스크립트_설명.md              ← bash 입문자용 해설
│   │   └── agent-app_리버스엔지니어링.md ← 바이너리 정적 분석 학습용 (선택)
│   └── html/
│       └── index.html                    ← tools/build_docs.py 가 생성한 정적 사이트
│
├── bin/
│   └── agent-app                   ← 운영 측 제공 Linux 바이너리 (Ubuntu 24.04 전용)
├── src/
│   ├── monitor.sh                  ← 시스템 상태 수집·로깅 (필수 산출물)
│   ├── report.sh                   ← 로그 분석 리포트 (보너스 1)
│   ├── archive_logs.sh             ← 시간 기반 로그 보존 (보너스 2)
│   │
│   ├── 00_run_all.sh               ← 01~07 setup 단계를 한 번에 실행 (wrapper)
│   ├── 01_ssh_hardening.sh         ← SSH 포트 20022 + Root 차단
│   ├── 02_firewall_allowlist.sh    ← UFW 화이트리스트 (20022/15034)
│   ├── 03_users_and_groups.sh      ← 계정 3종 + 그룹 2종
│   ├── 04_directories_and_acl.sh   ← 디렉토리 + ACL (default 상속 포함)
│   ├── 05_env_and_keyfile.sh       ← 환경변수 5종 + API 키 파일
│   ├── 06_deploy_app_and_scripts.sh ← agent-app + *.sh 배포
│   └── 07_cron_schedule.sh         ← cron 매분/매일 등록
│
├── demo.sh                         ← 시연 자동화 (시연 모드)
├── verify_orbstack.sh              ← OrbStack 기반 자동 검증 (src/01~07 을 그대로 실행하고 결과를 단언)
│
├── tools/                          ← 분석 / 문서 빌드 도구 (학습용)
│   ├── build_docs.py               ← docs/md/*.md + README.md → docs/html/index.html
│   ├── analyze_binary.py           ← agent-app ELF / PyInstaller 정적 분석
│   ├── extract_pyinstaller.py      ← PyInstaller 번들 추출
│   ├── decompile_metadata.py       ← .pyc code object 메타데이터 재귀 덤프
│   └── disasm_pyc.py               ← dis 모듈 기반 바이트코드 분해
│
└── .github/workflows/verify.yml    ← GitHub Actions 자동 검증
```

## 3. 최종 산출물

| # | 산출물 | 비고 |
| - | ------ | ---- |
| 1 | [요구사항_수행_내역서.md](docs/md/요구사항_수행_내역서.md) | 설정/명령어/검증 출력을 모은 제출 문서 |
| 2 | [src/monitor.sh](src/monitor.sh) | 시스템 상태 수집 + 로깅 (필수) |
| 3 | [src/report.sh](src/report.sh) | 로그 분석 리포트 (보너스 1) |
| 4 | [src/archive_logs.sh](src/archive_logs.sh) | 시간 기반 로그 보존 정책 (보너스 2) |
| 5 | [src/00_run_all.sh](src/00_run_all.sh) ~ [src/07_cron_schedule.sh](src/07_cron_schedule.sh) | 환경 구축 7단계 스크립트 (각 단계 분리, 번호 순서대로 실행) |
| 6 | `bin/agent-app` | 미션 측이 제공하는 Linux 바이너리 (Ubuntu 24.04 전용). 학습자가 만들지 않음 |
| 7 | [스크립트_설명.md](docs/md/스크립트_설명.md) | bash 입문자용 스크립트 해설 |

---

## 3. 기능 요구 사항

### 3.1 SSH

- 포트를 **20022** 로 변경
- **root 원격 로그인 차단** (`PermitRootLogin no`)
- 검증: `grep -E '^(Port|PermitRootLogin)' /etc/ssh/sshd_config` / `ss -tulnp`

### 3.2 방화벽 (UFW 또는 firewalld 택1)

- 활성화 후 **인바운드는 `20022/tcp`(SSH), `15034/tcp`(APP) 만 허용**
- "만 허용"은 규칙을 더해서가 아니라 **남은 규칙을 지워야** 성립한다 — `02_firewall_allowlist.sh` 가 그 둘이 아닌 인바운드 허용 규칙(`ALLOW IN`·`LIMIT IN`)을 번호 역순으로 제거하고, 같은 스크립트와 `verify_orbstack.sh` `v2_ufw()` 가 "예외 0건"을 단언한다
- 검증: `ufw status` 또는 `firewall-cmd --list-all`

### 3.3 계정 / 그룹

| 계정 | 역할 | 소속 그룹 |
| ---- | ---- | --------- |
| `agent-admin` | 운영/관리, cron 실행자 | `agent-common`, `agent-core` |
| `agent-dev`   | 개발/운영, monitor.sh 작성자 | `agent-common`, `agent-core` |
| `agent-test`  | QA/테스트 | `agent-common` |

| 그룹 | 멤버 |
| ---- | ---- |
| `agent-common` | admin, dev, test |
| `agent-core`   | admin, dev |

### 3.4 디렉토리 구조 & ACL

```
$AGENT_HOME                          (= /home/agent-admin/agent-app)
├── upload_files/   ← group=agent-common, R/W
├── api_keys/       ← group=agent-core ONLY, R/W
└── bin/            ← monitor.sh 등 자동화 스크립트
/var/log/agent-app/ ← group=agent-core ONLY, R/W
```

- ACL `-d`(default) 옵션으로 신규 파일도 동일 권한 자동 상속

### 3.5 애플리케이션 실행 환경

환경 변수:

| 변수 | 값 |
| ---- | -- |
| `AGENT_HOME` | `/home/agent-admin/agent-app` |
| `AGENT_PORT` | `15034` |
| `AGENT_UPLOAD_DIR` | `$AGENT_HOME/upload_files` |
| `AGENT_KEY_PATH` | `$AGENT_HOME/api_keys/t_secret.key` |
| `AGENT_LOG_DIR` | `/var/log/agent-app` |

키 파일: `$AGENT_HOME/api_keys/t_secret.key` 내용 = `agent_api_key_test` (1줄)

성공 기준:

- 일반 계정으로 실행 (루트 금지)
- Boot Sequence **5단계 모두 `[OK]`** + `Agent READY` 출력
- `0.0.0.0:15034` LISTEN
- 종료는 `Ctrl+C`

### 3.6 monitor.sh

| 항목 | 정책 |
| ---- | ---- |
| 위치 | `$AGENT_HOME/bin/monitor.sh` |
| 소유 | `agent-dev:agent-core` |
| 권한 | `750` (`rwxr-x---`) |
| 실행 계정 | `agent-admin` (cron) |

동작:

1. **Health Check (실패 시 `exit 1`)**
   - 프로세스 `agent-app` 실행 여부
   - TCP `15034` LISTEN 여부
2. **상태 점검 (경고만)**
   - 방화벽 활성 상태 → 비활성 시 `[WARNING]`
3. **자원 수집**
   - CPU 사용률(%) / MEM 사용률(%) / 디스크 사용률(/, Used %)
   - CPU 는 `top -bn2 -d 1` 의 **두 번째 샘플** — 1회 샘플은 부팅 이후 누적 평균에 가까워 '지금'이 아니다
4. **임계값 경고 (경고만)**
   - CPU `> 20%`, MEM `> 10%`, DISK `> 80%` → `[WARNING]`
5. **로그 기록**
   - 파일: `/var/log/agent-app/monitor.log`
   - 포맷: `[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%`
6. **로그 용량 관리**
   - 최대 **10MB / 10개 파일** 유지 (logrotate 또는 스크립트 자체 로직)

### 3.7 cron

- `agent-admin` 계정 crontab 에 `monitor.sh` **매분 실행** 등록
- 1~2분 내 `monitor.log` 신규 라인 누적 확인

---

## 4. 보너스 과제

### 보너스 1 — `report.sh`

`monitor.log` 분석:

- CPU/MEM/DISK 의 **평균/최대/최소 + 샘플 수** 콘솔 출력
- (선택) 시작/종료 시간 인자로 받아 구간 분석

### 보너스 2 — 시간 기반 로그 보존 정책 (`archive_logs.sh`)

- **7일 경과** `/var/log/agent-app/*.log` → `gzip` 압축
- 아카이브 이동: `/var/log/monitor/agent-app/archive/`
  - 이 디렉토리는 `04_directories_and_acl.sh` 가 **setup 단계에서** 만든다(`root:agent-core`, `770`). cron 실행자 `agent-admin` 은 `/var/log` 아래에 디렉토리를 만들 수 없으므로, 만드는 일과 쓰는 일의 권한 경계를 나눈 것
- **30일 경과** `*.gz` 삭제
- 디렉토리 미존재 / 권한 부족 / 대상 0개 → 안전 종료(WARNING)

---

## 5. 제약 사항

- 자동화 스크립트는 **Bash 로만** (Python 등으로 대체 금지)
- 필요한 경우에만 `sudo` 사용 (일반 계정 작업 권장)
- 제공된 Python 앱은 **실행 대상**일 뿐, 과제 핵심은 관제/자동화 스크립트 구현

---

## 6. 빠른 실행 가이드 (OrbStack)

```bash
# macOS 호스트
brew install orbstack
orb create ubuntu:24.04 codyssey
orb push -m codyssey src/*.sh bin/agent-app /tmp/   # 01~07 + monitor/report/archive + 바이너리
orb shell -m codyssey

# 머신 내부 (Windows 작성 파일이면 CRLF 정리)
sudo apt-get install -y dos2unix
dos2unix /tmp/*.sh && chmod +x /tmp/*.sh

# 이후 01~07 setup 스크립트를 순서대로 실행
bash /tmp/00_run_all.sh           # 한 번에 (권장)
# 또는 단계별로 직접 확인하며:
bash /tmp/01_ssh_hardening.sh
bash /tmp/02_firewall_allowlist.sh
# ...
bash /tmp/07_cron_schedule.sh
```

검증 체크리스트는 [요구사항_수행_내역서.md](docs/md/요구사항_수행_내역서.md) 마지막 절 참고.

### OrbStack 업데이트 알림 끄기 (선택)

`orb` 명령마다 "OrbStack X.Y.Z 업데이트 가능" 안내가 떠 시연에 거슬리는 경우 한 가지 이상의 방법으로 비활성화 가능.

**A) macOS 셸 프로파일에 영구 등록 (권장)**

```bash
# zsh 사용자
echo 'export ORBSTACK_NO_UPDATE_CHECK=1' >> ~/.zshrc
echo 'export ORB_NO_UPDATE_CHECK=1'      >> ~/.zshrc

# bash 사용자
echo 'export ORBSTACK_NO_UPDATE_CHECK=1' >> ~/.bashrc

source ~/.zshrc   # 또는 새 터미널 열기
```

**B) OrbStack 앱 자체 설정**

OrbStack 메뉴바 아이콘 → **Settings** → **System** → **Software Update** 에서 "Check for updates automatically" 체크 해제.

**C) 본 저장소 스크립트 사용 시**

`demo.sh` / `verify_orbstack.sh` 안에서 위 환경변수를 자동 set 하고, 새는 안내 줄은 `sed` 필터로 제거하도록 처리해 두었음 → 별도 작업 불필요.

---

## 7. 필수 증거 자료 체크리스트

- [ ] SSH `Port 20022` / `PermitRootLogin no` 적용 + `ss -tulnp` LISTEN 확인
- [ ] `ufw status` (또는 `firewall-cmd --list-all`) — `20022/tcp`, `15034/tcp` 만 ALLOW
- [ ] `id agent-admin / agent-dev / agent-test` 출력
- [ ] `ls -ld` + `getfacl` 로 디렉토리 권한 & ACL 확인
- [ ] 앱 Boot Sequence 5/5 `[OK]` + `Agent READY` 출력
- [ ] `0.0.0.0:15034` LISTEN 확인 (`ss -tlnp`)
- [ ] `monitor.sh` 수동 실행 결과 (HEALTH / RESOURCE / WARNING)
- [ ] `/var/log/agent-app/monitor.log` 최근 라인
- [ ] `crontab -l` 등록 + 1분 후 로그 라인 증가 확인

---

## 8. 개발 환경

- Ubuntu 24.04 LTS (OrbStack 머신 권장)
- bash, ss/netstat, ufw 또는 firewalld, acl(`setfacl`/`getfacl`), cron, python3
