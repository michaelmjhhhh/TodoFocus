# Improve Quick Capture voice recognition quality (EN primary, ZH fallback)

## Goals
- Use English as primary recognition locale with Chinese fallback.
- Add explicit UI reminder about language strategy.
- Change result fusion strategy to: final transcript has priority, partial transcript is preview only.
- Add short silence auto-finalize endpoint behavior.
- Keep local-only implementation (no cloud API dependency).

## Scope
- `QuickCaptureService` recognition state and fusion policy.
- `QuickCaptureView` UI reminder and preview display.

## Acceptance Criteria
- Recognition chooses `en-US` final text first, then `zh-CN` final as fallback.
- Partial text does not overwrite committed draft; it is preview-only.
- Recording auto-stops after short silence inactivity.
- Full tests/build pass.
