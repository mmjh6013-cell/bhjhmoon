# 📦 SAP SD Commercial Invoice & Data Dictionary

본 저장소는 SAP ERP / S/4HANA SD(Sales and Distribution) 모듈의 **Commercial Invoice (상업송장 발행)** ABAP 프로그램 소스코드와 **데이터 딕셔너리(Data Dictionary) 명세서** 작업 내역을 관리합니다.

---

## 📁 디렉토리 및 파일 구성

### 1. ABAP 프로그램 (`ZSDR0150`)
- [`ZSDR0150.abap`](./ZSDR0150.abap) : 상업송장(Commercial Invoice) 발행 메인 리포트 프로그램
- [`ZSDR0150_TOP.abap`](./ZSDR0150_TOP.abap) : 전역 데이터 선언 및 ALV 구조 정의
- [`ZSDR0150_CLS.abap`](./ZSDR0150_CLS.abap) : ALV 이벤트 핸들러 로컬 클래스 정의 및 구현
- [`ZSDR0150_SCN.abap`](./ZSDR0150_SCN.abap) : 조회 조건 선택화면 (Selection Screen)
- [`ZSDR0150_F01.abap`](./ZSDR0150_F01.abap) : 비즈니스 로직, 데이터 조회/가공, 서브루틴
- [`ZSDR0150_O01.abap`](./ZSDR0150_O01.abap) : PBO(Process Before Output) 화면 모듈
- [`ZSDR0150_I01.abap`](./ZSDR0150_I01.abap) : PAI(Process After Input) 사용자 명령 처리 모듈

### 2. 데이터 딕셔너리 명세서
- 📘 [**DATA_DICTIONARY_SPECIFICATION.md**](./DATA_DICTIONARY_SPECIFICATION.md) : SD 모듈 16개 커스텀 테이블 및 구조체 통합 데이터 명세서 (ERD, 필드 정의, 도메인 고정값 포함)
- 📂 [**dictionary/**](./dictionary/) : SE11 추출 원본 HTML 정의서 (16개 객체) 및 [README.md](./dictionary/README.md)

---

## 📊 데이터 딕셔너리 요약 (16개 객체)

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
