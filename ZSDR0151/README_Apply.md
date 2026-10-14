# ZSDR0151 개발 초안 및 적용 안내

작성일: 2026-10-14. 기준: 첨부 0150 v3 MD, v3.3 TXT의 기존 소스·화면, 최신 DDIC 및 대화 확정사항.

**상태: 전체 Include와 SE51 업로드용 후보 파일 작성, 로컬 정적 점검 완료. SAP 활성화·DB 저장·화면 업로드·런타임 테스트는 미실행.** 이 패키지를 운영 반영 완료본으로 간주하지 않는다.

## 1. 구성 및 적용 순서

1. SE38/SE80에서 실행 프로그램 `ZSDR0151`과 동일 이름의 `_TOP`, `_CLS`, `_SCN`, `_F01`, `_O01`, `_I01` Include를 생성한다. 각 `.abap` 파일 전체를 적용한다. 기존 0150은 복사 기준이다.
2. `ZSDR0151_Text_Elements.tsv`의 2열을 0151 Text Symbol로 등록한다. `ZSDR0151_Selection_Texts.tsv`는 선택 텍스트로 등록한다. 텍스트 길이는 영어 문자열 실제 길이 이상으로 설정한다. 메시지 클래스는 기존 ZSDM이다. `s001`, `s022`는 제공 소스의 기존 메시지 사용을 유지한다.
3. SE51에서 `ZSDR0151_0100_SE51.txt`, `0110`, `0200`을 해당 화면에 업로드하고 아래 속성을 대조한다. 화면 0300/0400은 SCN의 Selection Screen으로 자동 생성되므로 SE51 수동 생성 대상이 아니다.
4. SE41에서 아래 GUI Status 및 Title을 만든다. 전체 프로그램과 화면을 함께 활성화한다.
5. 아래 시스템 검증과 인수 테스트를 개발 클라이언트에서 수행한다.

### GUI Status / Title

| Status | 상태 유형 | Function Code | 표시명 / 설정 |
|---|---|---|---|
| 0100 | M | LIST | 첫 버튼. 동적 텍스트 필드 `GV_LIST_BTN`(SMP_DYNTXT) 연결 |
| 0100 | M | COPY | Copy |
| 0100 | M | SAVE | Save |
| 0100 | M | CHG_DIS | Display / Change |
| 0100 | M | PLUPLOAD | Packing List Upload |
| 0100 | M | PRINT | Print |
| 0100 | M | DELIV_HOT | Display Delivery. F2도 동일 코드로 연결 가능 |
| 0100 | M | BACK / EXIT / CANC | Back / Exit / Cancel |
| 0200 | P | PICK | Select |
| 0200 | P | BACK / EXIT / CANC | Cancel |

- Title `0100`: Commercial Invoice and Packing List. Title `0200`: Select Delivery.
- **Back/Exit/Cancel도 일반 Function Type(공란)으로 설정한다.** 본 구현은 PAI에서 최신 헤더 값을 전송하고 ALV/TextEdit 값을 읽은 뒤 종료 여부를 확인한다. E 타입 Exit Command를 임의로 추가하면 이 흐름을 우회한다.
- 잠금 실패 시 수정모드로 전환하지 않는다. 기존 문서 수정모드 진입은 잠금 후 재조회한다.

### SE51 화면

| 화면 | 유형 / OK Code | 요소 | 위치(행, 열) / 크기(높이, 폭) |
|---|---|---|---|
| 0100 | Normal / GV_OKCODE | CC_INV | (1, 2), 26 × 44 |
| 0100 | Normal | BX_HEADER | (1, 48), 19 × 172 |
| 0100 | Normal | CC_REMARK | (21, 48), 6 × 172 |
| 0100 | Normal | SUB_ITEM | (27, 2), 18 × 218 |
| 0110 | Subscreen / 없음 | CC_ITEM | (1, 2), 18 × 218 |
| 0200 | Modal Dialog Box / GV_POP_OKCODE | GV_POP_VBELN | 직접 입력 필드, LIKP-VBELN 호환, ALPHA |
| 0200 | Modal Dialog Box | CC_POP | (3, 2), 19 × 118 |

- 0100 크기 44행 × 220열, 0110 크기 18행 × 220열, 0200 크기 22행 × 120열.
- 기존 export 직렬화 형식을 보존하고 프로그램명·관찰 가능한 좌표·컨트롤·Flow Logic을 수정했다. SAP GUI에서 import 성공을 확인한 파일은 아니다. 릴리스별 화면 header/control 속성은 위 표를 기준으로 재확인한다.
- 기존 0100 export에는 DDIC 최신값과 다른 길이 메타데이터가 있다. **SE51에서 GS_HEAD 필드를 현재 ZSDS0060_H 정의로 갱신해야 한다.** 특히 `ZIVH01 CHAR500`, `ZIVH08 CHAR240`, `ZIVH11 DATS`, `ZIVH12 CHAR10`을 확인한다. 500자 입력·보존 테스트 전까지 긴 텍스트 입력 지원을 완료로 판단하지 않는다.
- `GS_HEAD-ZIVH13/21/27`은 DIS 및 조회 전용. `TOTAL_AMOUNT`는 `GS_HEAD-WAERK`, 수량 필드는 대응 단위와 연결한다.
- LIST는 좌측 목록의 표시만 토글한다. 숨김 시 헤더를 왼쪽으로 늘리는 재배치는 구현하지 않았다. 하단 품목 ALV는 항상 전체 폭이다.
- Delivery 이동은 툴바의 `DELIV_HOT`로 제공한다. Dynpro 필드에 ALV의 hotspot 속성을 가정하지 않는다.
- CBM은 T006/CUNIT 표시 설정에 영향을 받는다. 내부 코드는 M3이며 본 코드는 표준 단위 표시를 사용한다.

## 2. 확정 규칙 및 데이터 표현

- F8은 항상 신규 초안. 기존 송장은 Document Overview 더블클릭으로 조회한다. 목록은 S_VBELN을 제외한 조회조건에 따른다.
- Delivery 1 : Invoice N 허용. Copy는 저장된 문서이며 미저장 변경이 없어야 한다. 같은 Ship-to만 선택하며 기발행 Delivery도 허용한다.
- Copy 시 새 Delivery/유형/총금액/통화/품목만 교체한다. 주소, Invoice Date, Package, 헤더 중량·체적, Shipping Remark, 현재 Import Invoice 표시를 보존한다. 대상 조회·계산 실패는 이전 문서와 캐시를 복원한다.
- `ZSDT0060/61/62`, `ZSDS0060_H`, `ZSDINVNO`, 장문 객체를 0150과 공유한다. 0151에서도 동일 DB 데이터에 반영된다.
- 신규 미패킹 품목은 표시용이며 0061에 저장하지 않는다. 패킹 변경 플래그가 없는 Save는 기존 0061을 보존한다. 패킹 품목 변경 시 키 검증 후 해당 Invoice 전체 교체를 같은 LUW에서 수행한다.
- `0061` 키는 MANDT/ZINVNO/ZPKGNO/MATNR. 동일 패킹 번호·자재에 서로 다른 Delivery POSNR를 넣는 경우 합치지 않고 오류로 차단한다. DDIC 키는 변경하지 않는다.
- `ZIVI02/03`은 INT4로 사용하고 임의 999 제한을 적용하지 않는다. BOX는 기본단위 수량/박스로 해석하며 숫자·양수·정수·INT4 범위를 검증한다. 불량 BOX는 카톤 수량 0과 품목 경고로 표시한다.
- 무게/체적 계산: `화면수량 × 화면단위→자재기본단위 계수 × 2011의 기본단위당 값`.
- 납품 판매단위 환산은 LIPS의 UMVKZ/UMVKN을 우선 사용한다(기본단위 일치 검증). 그 외 단위는 MARM을 사용한다. 2011의 단위는 MARA-GEWEI/VOLEH를 읽고 KG/M3로 변환하여 신규 계산 결과를 0061에 저장한다.
- 0061 재조회는 MEINS/WAERS를 우선하고 비어 있으면 Delivery 판매단위/참조 SO 통화로 보충한다. 가격조건 통화가 문서 통화와 다르면 임의 환율을 적용하지 않고 차단한다.
- `NETPR`는 외부 표현의 단위당 가격(DEC), `NETWR`는 SAP 내부 표현(CURR). CM `CONV_CURR`로 표현 변환하며 ALV NETWR은 WAERK를 참조한다. 저장 컬럼은 WAERS로 명시적으로 매핑한다.
- ZSR2 우선, 없으면 ZSR1. 선택 조건이 여러 활성 행이거나 수량기준 조건이 아니면 임의 선택 없이 오류. 조건 KMEIN 단위와 납품 단위를 환산하고 KPEIN을 적용한다.
- 소수 자릿수는 `TYPE zsdt0061-...`를 통해 활성 DDIC를 따른다. 계산 중간값은 DECFLOAT34, CM 전달은 공개 타입 TY_DEC31_14를 사용한다. 저장형보다 세밀한 값은 저장형 정밀도로 반올림될 수 있다.
- 헤더 총금액/통화는 0060에 없으므로 재조회 시 품목에서 복원한다. 헤더 단독 저장 건은 Delivery 현재 데이터로 금액을 계산한다. 저장 중량/체적은 재집계하지 않는다.
- Import Invoice는 CHAR20 표시 필드이고 DB 미저장이다. Copy 직후는 원본 표시를 보존하나 이후 저장 문서 재조회에서는 새 참조 Delivery의 구매송장으로 다시 조회한다. 복수 번호 연결은 20자에서 잘린다. 전체 번호/과거 시점 값을 보존하려면 별도 DDIC 확장이 필요하다.
- Shipping Remark는 ZSDINV / 001 / Invoice No / SY-LANGU에 저장한다. 빈 텍스트로 저장하면 기존 장문을 삭제한다. ZIVH14에는 별도 요약을 생성하지 않는다.
- 최초 Bill-to 기본값은 첨부 TXT의 Payer 의도를 따라 내부 역할 RG를 사용한다. 복수 지급조건 또는 복수 지급처는 임의 첫 행 대신 사용자 필수 입력으로 남긴다.
- 배치분할 상위 행은 자식이 있으면 표시/계산에서 제외하여 수량을 이중 집계하지 않는다.

## 3. 채번 / 저장 경계

1. 신규 Save만 Ship-to NAME4 접두어와 영업조직을 검증한다.
2. 매핑: 1000=A / 2200=S / 2300=P / 2600=K. Subobject는 접두어3자리+문자1자리.
3. 번호범위 객체 잠금 후 0062와 현재 시스템 연도/구간01을 재확인한다. 없는 0062와 구간0001~9999만 생성한다. 기존 구간은 덮어쓰지 않으며 다른 구간 정의는 오류로 표시한다.
4. 번호 구간 준비는 **업무 DB 변경 이전의 별도 LUW**에서 확정한다. 따라서 Invoice 저장 실패 후에도 새 Subobject/구간은 남을 수 있다.
5. NUMBER_GET_NEXT 후 신규 Invoice 번호 잠금. 헤더/패킹/장문은 한 업무 DB LUW에서 반영한다. 신규는 INSERT로만 저장하므로 번호 중복으로 기존 문서를 덮어쓰지 않는다.
6. 오류 시 ROLLBACK, 화면 입력 유지. 번호를 강제로 되돌리지 않는다. 정상 저장 후 조회모드·잠금해제·목록갱신.
7. 기존 Invoice 수정은 채번 마스터를 다시 검증하지 않으며 번호를 유지한다.

### SAP에서 확인할 인터페이스/설정

- 사용자가 생성한 ENQUEUE_EZ_ZSDT0060 / DEQUEUE_EZ_ZSDT0060의 실제 파라미터가 MANDT/ZINVNO인지 확인. 잠금 범위는 Invoice 헤더와 그 품목 전체여야 한다. `_SCOPE = '1'`로 대화 소유 잠금을 사용한다.
- SNRO ZSDINVNO: Subobject, To Financial Year, 내부 구간01, **Do Not Roll Over(재시작 금지)**. 현재 버퍼링 설정에 따른 결번과 동시 채번도 테스트한다.
- SE37에서 NUMBER_RANGE_INTERVAL_UPDATE(INTERVAL/ERROR_IV: INRIV, ERROR_OCCURED), NUMBER_RANGE_UPDATE_CLOSE, NUMBER_RANGE_UPDATE_INIT 인터페이스와 대상 릴리스의 COMMIT 동작 확인.
- CM POPUP_TO_CONFIRM 결과 Y/N, FILE_OPEN_DIALOG E_MSG, TABLE_TO_FIELDCATALOG의 IT_TAB/RT_FIELDCATALOG, CONV_CURR 입력/출력과 공개 TY_DEC31_14를 대조한다. 현재 클래스가 스킬 참조본과 다른 경우 해당 FORM 호출부만 조정한다.
- CM CONV_MAT_UNIT은 오류 반환이 없으므로 이번 코드에서는 실패 감지가 가능한 명시적 환산을 사용했다.
- SAPscript 장문 객체/ID가 활성이고 직접 저장 모드가 제공되는지 확인한다. 업무 DML과 텍스트 저장 사이에 추가 COMMIT을 넣지 않는다.
- 기존 0061 테스트 데이터의 NETPR가 외부 단가인지, 중량/체적이 KG/M3로 저장되었는지 확인한다. 이전 데이터 표현이 다르면 먼저 변환 또는 조회 규칙을 맞춰야 한다.

공식 번호범위 API 흐름 참고: [SAP Help — Number range read and maintain services](https://help.sap.com/saphelp_ewm900/helpdata/en/48/d7a0b1a69d3e49e10000000a421937/content.htm). 실제 활성 인터페이스는 대상 시스템이 기준이다.

## 4. 현 단계 후속 범위

실제 Excel 파싱·행 배분·패킹 번호 생성과 Smart Forms/Adobe/Excel 출력 엔진은 명세대로 후속 범위다. 이번 코드는 종류 선택/파일 선택/출력 사전검사/각 FORM 분기/영어 미구현 안내까지 제공한다. 따라서 이 버전에서 새 패킹 데이터를 Excel로 생성할 수 없고 기존 저장 패킹의 조회·편집은 가능하다.

후속 업로드는 임시 테이블 전체 검증 성공 후 GT_ITEM 전체 교체, GV_PACK_DIRTY/GV_CHANGED 설정, 헤더 재집계를 해야 한다. 업로드 FORM 자체에서 DB 변경이나 채번을 하지 않는다.

## 5. 개발계 인수 테스트

- [ ] 모든 Include/화면 활성화 및 SE51 필드 타입 일치. 500자 Ship-to 입력/재조회 보존.
- [ ] F8 신규 초안, 헤더 단독 Save, 동일 Delivery에 Invoice 두 건 발행.
- [ ] 0061 없는 헤더가 목록에 표시되고 출력은 차단됨.
- [ ] 헤더 수정 Save 후 기존 0061 행 수/값이 그대로 유지됨.
- [ ] 조회→수정 잠금 실패 시 조회모드 유지. 두 세션의 동시 최초 구간생성/저장.
- [ ] 새 시스템 연도 구간 자동생성, 기존 구간 유지, 9999 소진 시 재시작 없음.
- [ ] CM 확인 팝업 No/Cancel이 입력을 유지함. 체크박스 선택만으로 변경 경고가 나오지 않음.
- [ ] ALV 최근 편집·헤더 최근 입력·TextEdit 입력이 저장/Copy/이동/종료 판단 전에 반영됨.
- [ ] Copy 취소/오류는 기존 문서 유지. Copy 성공 후 신규번호 공란, 원본 헤더 보존.
- [ ] 직접 입력/목록선택/더블클릭 Delivery 동기화. 다른 Ship-to 차단.
- [ ] 패킹 수량 변경 시 기본단위 환산·카톤·중량·체적·금액 갱신. 수동 중량 변경은 다른 행을 재계산하지 않음.
- [ ] BOX 공백/문자/0, 단위마스터 누락, 정수·금액 범위 초과가 덤프 없이 처리됨.
- [ ] KRW/JPY/USD: 최초 단가, 금액, 저장, 재조회 후 금액 동일.
- [ ] 판매단위≠기본단위, 조건단위≠판매단위, G→KG, CM3→M3 계산.
- [ ] SAVE_TEXT 실패 주입 시 헤더/품목 롤백, 입력 유지, 기존 텍스트 유지.
- [ ] 저장 장문 삭제, Copy 장문 신규 저장 시 원본 텍스트 보존.
- [ ] 업로드/출력 미구현 분기는 DB/번호/변경 상태를 바꾸지 않음.

로컬 검사는 `STATIC_CHECK.txt`에 기록했다. 이는 ABAP 컴파일러 또는 SAP 실행 결과가 아니다.