;; Prediction Market Contract

(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))

(define-data-var market-nonce uint u0)

(define-map markets
  { market-id: uint }
  {
    creator: principal,
    description: (string-utf8 500),
    options: (list 10 (string-utf8 50)),
    end-block: uint,
    total-stake: uint,
    resolved: bool,
    winning-option: (optional uint)
  }
)

(define-map bets
  { market-id: uint, better: principal }
  { option: uint, amount: uint }
)

(define-public (create-market (description (string-utf8 500)) (options (list 10 (string-utf8 50))) (duration uint))
  (let
    ((market-id (+ (var-get market-nonce) u1)))
    (asserts! (> (len options) u0) (err u400))
    (map-set markets
      { market-id: market-id }
      {
        creator: tx-sender,
        description: description,
        options: options,
        end-block: (+ block-height duration),
        total-stake: u0,
        resolved: false,
        winning-option: none
      }
    )
    (var-set market-nonce market-id)
    (ok market-id)
  )
)

(define-public (place-bet (market-id uint) (option uint) (amount uint))
  (let
    ((market (unwrap! (map-get? markets { market-id: market-id }) ERR_NOT_FOUND))
     (current-bet (default-to { option: u0, amount: u0 } (map-get? bets { market-id: market-id, better: tx-sender }))))
    (asserts! (not (get resolved market)) ERR_UNAUTHORIZED)
    (asserts! (< block-height (get end-block market)) ERR_UNAUTHORIZED)
    (asserts! (< option (len (get options market))) ERR_UNAUTHORIZED)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set markets { market-id: market-id }
      (merge market { total-stake: (+ (get total-stake market) amount) })
    )
    (map-set bets { market-id: market-id, better: tx-sender }
      { option: option, amount: (+ (get amount current-bet) amount) }
    )
    (ok true)
  )
)

(define-public (resolve-market (market-id uint) (winning-option uint))
  (let
    ((market (unwrap! (map-get? markets { market-id: market-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get creator market)) ERR_UNAUTHORIZED)
    (asserts! (>= block-height (get end-block market)) ERR_UNAUTHORIZED)
    (asserts! (not (get resolved market)) ERR_UNAUTHORIZED)
    (asserts! (< winning-option (len (get options market))) ERR_UNAUTHORIZED)
    (ok (map-set markets { market-id: market-id }
      (merge market { resolved: true, winning-option: (some winning-option) })
    ))
  )
)

(define-public (claim-winnings (market-id uint))
  (let
    ((market (unwrap! (map-get? markets { market-id: market-id }) ERR_NOT_FOUND))
     (bet (unwrap! (map-get? bets { market-id: market-id, better: tx-sender }) ERR_NOT_FOUND)))
    (asserts! (get resolved market) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get option bet) (unwrap! (get winning-option market) ERR_UNAUTHORIZED)) ERR_UNAUTHORIZED)
    (let
      ((winnings (/ (* (get amount bet) (get total-stake market)) (get amount bet))))
      (try! (as-contract (stx-transfer? winnings tx-sender tx-sender)))
      (map-delete bets { market-id: market-id, better: tx-sender })
      (ok winnings)
    )
  )
)

(define-read-only (get-market (market-id uint))
  (ok (unwrap! (map-get? markets { market-id: market-id }) ERR_NOT_FOUND))
)

(define-read-only (get-bet (market-id uint) (better principal))
  (ok (unwrap! (map-get? bets { market-id: market-id, better: better }) ERR_NOT_FOUND))
)

