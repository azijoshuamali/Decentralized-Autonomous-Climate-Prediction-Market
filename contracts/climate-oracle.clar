;; Climate Oracle Contract

(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))

(define-map authorized-data-providers principal bool)

(define-map climate-data
  { data-id: uint }
  {
    provider: principal,
    timestamp: uint,
    temperature: int,
    precipitation: uint,
    wind-speed: uint
  }
)

(define-data-var data-nonce uint u0)

(define-public (register-data-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-caller) ERR_UNAUTHORIZED)
    (ok (map-set authorized-data-providers provider true))
  )
)

(define-public (submit-climate-data (temperature int) (precipitation uint) (wind-speed uint))
  (let
    ((data-id (+ (var-get data-nonce) u1)))
    (asserts! (default-to false (map-get? authorized-data-providers tx-sender)) ERR_UNAUTHORIZED)
    (map-set climate-data
      { data-id: data-id }
      {
        provider: tx-sender,
        timestamp: block-height,
        temperature: temperature,
        precipitation: precipitation,
        wind-speed: wind-speed
      }
    )
    (var-set data-nonce data-id)
    (ok data-id)
  )
)

(define-read-only (get-climate-data (data-id uint))
  (ok (unwrap! (map-get? climate-data { data-id: data-id }) ERR_NOT_FOUND))
)

