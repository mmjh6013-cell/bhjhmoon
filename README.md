# 📦 SAP SD Commercial Invoice & Programs Repository

본 저장소는 SAP ERP / S/4HANA SD(Sales and Distribution) 모듈의 **Commercial Invoice (상업송장 발행)** 및 관련 SD 프로그램, **데이터 딕셔너리(Data Dictionary) 명세서**, Clean ABAP 가이드, 그리고 **SAP S/4HANA 공식/참조 문서(PDF)**를 통합 관리합니다.

---

## 📁 디렉토리 및 구성 내역

### 1. 상업송장 발행 프로그램 (`ZSDR0150`)
- [`ZSDR0150.abap`](./ZSDR0150.abap) : 상업송장 발행 메인 리포트 프로그램
- [`ZSDR0150_TOP.abap`](./ZSDR0150_TOP.abap) : 전역 데이터 선언 및 ALV 구조 정의
- [`ZSDR0150_CLS.abap`](./ZSDR0150_CLS.abap) : ALV 이벤트 핸들러 로컬 클래스
- [`ZSDR0150_SCN.abap`](./ZSDR0150_SCN.abap) : 조회조건 선택화면
- [`ZSDR0150_F01.abap`](./ZSDR0150_F01.abap) : 비즈니스 로직 및 서브루틴
- [`ZSDR0150_O01.abap`](./ZSDR0150_O01.abap) : PBO 화면 모듈
- [`ZSDR0150_I01.abap`](./ZSDR0150_I01.abap) : PAI 화면 모듈

### 2. 상업송장 관리 고도화 패키지 (`ZSDR0151`)
- 📂 [**ZSDR0151/**](./ZSDR0151/) : 상업송장 확장 프로그램 소스 및 화면 정의
  - 메인/인클루드: `ZSDR0151.abap`, `TOP`, `CLS`, `SCN`, `F01`, `O01`, `I01`
  - SE51 스크린 정의: `0100`, `0110`, `0200` 화면 텍스트 및 레이아웃
  - 텍스트 엘리먼트 & Selection Texts
  - 적용 가이드: `README_Apply.md`, `STATIC_CHECK.txt`
- 📂 [**ZSDR0151_O01_I01_Fix/**](./ZSDR0151_O01_I01_Fix/) : 화면 PBO/PAI 모듈 보완 패키지

### 3. 출하/인보이스 연계 프로그램 (`ZSDR0160`)
- 📂 [**ZSDR0160/**](./ZSDR0160/) : ZSDR0160 소스 패키지
  - 메인/인클루드: `ZSDR0160.abap`, `TOP`, `CLS`, `SCN`, `F01`, `O01`, `I01`
  - 텍스트 엘리먼트 정의: `TEXT_ELEMENTS_TSV.txt`

### 4. 데이터 딕셔너리 명세서
- 📘 [**DATA_DICTIONARY_SPECIFICATION.md**](./DATA_DICTIONARY_SPECIFICATION.md) : **SD 모듈 16개 커스텀 테이블/구조체 통합 명세서** (ERD 다이어그램, 상세 필드 정의, 도메인 고정값 매핑)
- 📂 [**dictionary/**](./dictionary/) : SE11 추출 원본 HTML 16개 파일 및 [README.md](./dictionary/README.md)

### 5. SAP S/4HANA 참조 문서 (PDF)
- 📂 [**pdf/**](./pdf/) : SAP S/4HANA 모듈별 공식 및 전문 참조 문서 (총 4권, 약 228MB)
  - 📕 `EWM with SAP S4HANA Architecture and Programming.pdf` (18.5 MB)
  - 📕 `Integrating Warehouse Management in SAP S4HANA.pdf` (76.9 MB)
  - 📕 `Inventory Management with SAP S4HANA.pdf` (59.0 MB)
  - 📕 `Materials Management with SAP S4HANA Business Processes and Configuration.pdf` (73.3 MB)

### 6. 개발 표준 및 가이드
- 📖 [**CleanABAP_kr.md**](./CleanABAP_kr.md) : Clean ABAP 한국어 개발 가이드라인

---

## 📊 데이터 딕셔너리 관리 객체 요약 (16개)

| 업무 영역 | 객체명 | 유형 | 주요 설명 |
|:---|:---|:---|:---|
| **판매 계획 관리** | `ZSDT0010` | Transparent Table | [SD] 연간 판매계획 관리 테이블 |
| | `ZSDT0020` | Transparent Table | [SD] 월간 판매계획 관리 테이블 |
| | `ZSDT0030` | Transparent Table | [SD] 주간 판매계획 관리 테이블 |
| | `ZSDT0040` | Transparent Table | [SD] 일일 서열 수급계획 관리 테이블 |
| | `ZSDT0070` | Transparent Table | [SD] 관계사 계획단가 조건 레코드 |
| | `ZSDT0080` | Transparent Table | [SD] 관계사별 고객 프로젝트 코드 매핑 |
| **상업송장 / 통관** | `ZSDT0060` | Transparent Table | [SD] Commercial Invoice 헤더 정보 관리 |
| | `ZSDT0061` | Transparent Table | [SD] Commercial Invoice 품목 및 패킹 정보 관리 |
| | `ZSDT0062` | Transparent Table | [SD] Commercial Invoice 번호 채번 서브오브젝트 |
| | `ZSDS0060_H` | Structure | [SD] Commercial Invoice 헤더 화면 I/O 구조체 |
| | `CI_PRS_CPILS_2` | CI Include | [SD] 대금청구 확장 구조체 (송장번호, B/L 번호) |
| **마감 및 인터페이스** | `ZSDT0050` | Transparent Table | [SD] VMI/CMI 월 판매 마감 실적 및 정산 테이블 |
| | `ZSDS0001` | Structure | [SD] 판매문서 Append 구조체 (구매발주 정보 연계) |
| | `ZSDS0002` | Structure | [SD] 판매문서 Append 구조체 (BAPE / BAPI 연계) |
| | `ZSDS0010` | Structure | [SD] 출고 반품 처리 결과 BAPI 리턴 메시지 구조체 |
| | `ZSDS0020` | Structure | [SD] 판매문서 구매정보 공통 인클루드 구조체 |
