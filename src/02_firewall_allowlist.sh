#!/usr/bin/env bash
# 02_firewall_allowlist.sh
# -----------------------------------------------------------------------------
# 단계 2 / 7 — UFW 방화벽 화이트리스트
#   • 들어오는 통신: 기본 거부 (default deny incoming)
#   • 나가는 통신:   기본 허용 (default allow outgoing)
#   • 예외만 허용:   20022/tcp (SSH), 15034/tcp (AGENT APP)
#   • systemd unit 도 명시적으로 enable + start
#     (OrbStack 같은 환경에선 `ufw enable` 만으론 unit 이 활성화되지 않을 수 있음)
#
# 실행 위치: 머신 안
# 권한:      sudo 가능한 계정
# -----------------------------------------------------------------------------

set -eu
step() { printf "  ▶ %s\n" "$*"; }

if ! command -v ufw >/dev/null 2>&1; then
    step "ufw 패키지 설치 중..."
    sudo apt-get update -qq
    sudo apt-get install -y ufw
else
    step "ufw 이미 설치돼 있음"
fi

step "기본 정책: incoming = deny, outgoing = allow"
sudo ufw default deny incoming
sudo ufw default allow outgoing

step "예외 허용: 20022/tcp (SSH)"
sudo ufw allow 20022/tcp comment 'SSH'
step "예외 허용: 15034/tcp (AGENT APP)"
sudo ufw allow 15034/tcp comment 'AGENT APP'

step "ufw 활성화 (룰 적용)"
sudo ufw --force enable

step "ufw.service systemd unit enable + start"
sudo systemctl enable --now ufw

# ── R1-4 의 "만 허용" 을 실제로 성립시키는 단계 ──────────────────────────────
# 위의 allow 2줄은 '추가' 일 뿐이라, 이전 실습이 열어 둔 22/tcp 나 OpenSSH 앱
# 프로파일이 남아 있으면 "20022/15034 만 허용" 이 아니다(= R1-4 위반).
# 규칙을 더하는 것으로는 배타성이 생기지 않는다. 남은 것을 지워야 생긴다.
#
# 안전 순서: 이 스크립트는 01_ssh_hardening.sh(=sshd 를 20022 로 이전) 다음에 돌고,
# 20022 는 바로 위에서 이미 허용했다. 그래서 여기서 22/tcp 를 닫아도 자기 자신을
# 잠그지 않는다. 01 을 건너뛰고 02 만 단독 실행하면 22 로 붙은 세션이 끊길 수 있다.
#
# 삭제는 반드시 '큰 번호부터'. ufw 는 한 줄 지울 때마다 뒤 번호를 당겨오기 때문에
# 작은 번호부터 지우면 엉뚱한 규칙이 사라진다.
#
# ALLOW 만 보면 안 된다 — 'ufw limit 22/tcp'(흔한 SSH brute-force 방어 레시피)가
# 남긴 LIMIT IN 도 인바운드를 '허용' 한다. 통과시키면 22 번이 열린 채 R1-4 가 OK 로 찍힌다.
step "20022/15034 이외의 인바운드 허용(ALLOW IN·LIMIT IN) 규칙 제거 (배타성 확보)"
extra_nums="$(sudo ufw status numbered 2>/dev/null \
    | sed -nE 's/^\[[[:space:]]*([0-9]+)\][[:space:]]+(.*)$/\1 \2/p' \
    | awk '$0 ~ / (ALLOW|LIMIT) IN / && $2 != "20022/tcp" && $2 != "15034/tcp" {print $1}' \
    | sort -rn)"
if [[ -z "${extra_nums}" ]]; then
    printf "      ✓ 삭제할 규칙 없음 (이미 20022/15034 만 허용)\n"
else
    for n in ${extra_nums}; do
        printf "      - ufw delete %s\n" "${n}"
        sudo ufw --force delete "${n}"
    done
fi

# 검증
echo
echo "─── 검증 ────────────────────────────"
sudo ufw status verbose
echo
echo "--- 배타성 확인: 20022/15034 이외의 인바운드 허용 규칙이 남아 있는가 ---"
leftover="$(sudo ufw status verbose \
    | awk '/(ALLOW|LIMIT) IN/ && $1 != "20022/tcp" && $1 != "15034/tcp"')"
if [[ -n "${leftover}" ]]; then
    echo "[ERROR] R1-4 위반 — 아래 인바운드 허용 규칙이 남아 있다:" >&2
    printf '%s\n' "${leftover}" >&2
    exit 1
fi
echo "OK: 허용된 인바운드는 20022/tcp, 15034/tcp 뿐"
echo "─────────────────────────────────────"
echo "[02] Firewall allowlist 완료"
