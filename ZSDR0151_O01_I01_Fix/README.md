# ZSDR0151 O01 / I01 교체본

- 첨부 TOP 및 직전 제공 ZSDR0151_F01.abap 기준입니다.
- O01 / I01 두 Include를 각각 전체 교체합니다. TOP / F01 추가 수정은 없습니다.
- 기존 0100/0110 MODULE 이름을 유지했습니다. Copy용 0200 MODULE도 포함했습니다.
- 0100 PAI는 기존대로 HEADER_INPUT_0100을 USER_COMMAND_0100보다 먼저 호출해야 합니다.
- EXIT는 기존 PROCESS AFTER INPUT의 MODULE EXIT AT EXIT-COMMAND 연결을 유지합니다.
- Document Overview 토글 버튼의 실제 Function Code는 LIST여야 합니다. SE41/SE51에서 확인하세요. 기존 GC_DOC_TOGGLE 값은 첨부 TOP에 없으므로 추정하지 않았습니다.
- CHG_DIS / OPEN_INV / PLUPLOAD / PRINT는 직전 개발본의 기능코드입니다. 실제 GUI Status와 화면 버튼의 설정은 SAP에서 확인해야 합니다.
- 0200 화면 및 GUI Status가 있어야 Copy 팝업을 실행할 수 있습니다.
- 활성화는 메인 ZSDR0151 기준으로 관련 Include를 함께 구문 검사합니다.

검증: O01/I01의 모든 PERFORM 대상 존재, 사용 GC_* 상수의 첨부 TOP 선언 존재, MODULE/ENDMODULE 쌍 확인.
SAP 구문 검사·활성화·실행은 수행하지 못했습니다. 조회/수정, 저장, 목록 토글, 편집 후 종료 취소를 시스템에서 확인하세요.