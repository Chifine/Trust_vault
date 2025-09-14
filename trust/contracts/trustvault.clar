;; TrustVault - Decentralized Escrow Service
;; Secure peer-to-peer transactions with automated dispute resolution

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ESCROW_NOT_FOUND (err u101))
(define-constant ERR_INVALID_STATE (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_DISPUTE_PERIOD_EXPIRED (err u104))
(define-constant ERR_ALREADY_DISPUTED (err u105))
;; Added new error constants for input validation
(define-constant ERR_INVALID_PRINCIPAL (err u106))
(define-constant ERR_INVALID_STRING (err u107))
(define-constant ERR_INVALID_ESCROW_ID (err u108))
(define-constant ERR_LIST_FULL (err u109))

;; Escrow States
(define-constant STATE_PENDING u1)
(define-constant STATE_FUNDED u2)
(define-constant STATE_COMPLETED u3)
(define-constant STATE_DISPUTED u4)
(define-constant STATE_RESOLVED u5)
(define-constant STATE_CANCELLED u6)

;; Data Variables
(define-data-var next-escrow-id uint u1)
(define-data-var platform-fee-rate uint u250) ;; 2.5% in basis points
(define-data-var dispute-period uint u1440) ;; 24 hours in blocks

;; Data Maps
(define-map escrows
  { escrow-id: uint }
  {
    buyer: principal,
    seller: principal,
    arbitrator: (optional principal),
    amount: uint,
    fee: uint,
    description: (string-ascii 500),
    state: uint,
    created-at: uint,
    funded-at: (optional uint),
    dispute-deadline: (optional uint),
    completion-code: (optional (string-ascii 32))
  }
)

(define-map user-escrows
  { user: principal }
  { escrow-ids: (list 50 uint) }
)

(define-map dispute-votes
  { escrow-id: uint, voter: principal }
  { vote: bool, voted-at: uint }
)

;; Added input validation helper functions
(define-private (validate-principal (principal-to-check principal))
  (not (is-eq principal-to-check 'SP000000000000000000002Q6VF78))
)

(define-private (validate-string (str (string-ascii 500)))
  (and (> (len str) u0) (<= (len str) u500))
)

(define-private (validate-completion-code (code (optional (string-ascii 32))))
  (match code
    some-code (and (> (len some-code) u0) (<= (len some-code) u32))
    true
  )
)

(define-private (validate-escrow-id (escrow-id uint))
  (and (> escrow-id u0) (< escrow-id (var-get next-escrow-id)))
)

;; Private Functions
;; Fixed add-escrow-to-user function with proper error constant
(define-private (add-escrow-to-user (user principal) (escrow-id uint))
  (let ((current-escrows (default-to (list) (get escrow-ids (map-get? user-escrows { user: user })))))
    (match (as-max-len? (append current-escrows escrow-id) u50)
      some-list (begin
        (map-set user-escrows 
          { user: user }
          { escrow-ids: some-list }
        )
        (ok true)
      )
      (err ERR_LIST_FULL)
    )
  )
)

(define-private (calculate-fee (amount uint))
  (/ (* amount (var-get platform-fee-rate)) u10000)
)

;; Public Functions

;; Create new escrow
(define-public (create-escrow 
  (seller principal)
  (amount uint)
  (description (string-ascii 500))
  (arbitrator (optional principal))
  (completion-code (optional (string-ascii 32)))
)
  (let ((escrow-id (var-get next-escrow-id))
        (fee (calculate-fee amount)))
    ;; Added comprehensive input validation
    (asserts! (> amount u0) ERR_INSUFFICIENT_FUNDS)
    (asserts! (not (is-eq seller tx-sender)) ERR_NOT_AUTHORIZED)
    (asserts! (validate-principal seller) ERR_INVALID_PRINCIPAL)
    (asserts! (validate-string description) ERR_INVALID_STRING)
    (asserts! (validate-completion-code completion-code) ERR_INVALID_STRING)
    (asserts! (match arbitrator
      some-arb (validate-principal some-arb)
      true
    ) ERR_INVALID_PRINCIPAL)
    
    ;; Store escrow
    (map-set escrows
      { escrow-id: escrow-id }
      {
        buyer: tx-sender,
        seller: seller,
        arbitrator: arbitrator,
        amount: amount,
        fee: fee,
        description: description,
        state: STATE_PENDING,
        ;; Updated block-height to stacks-block-height
        created-at: stacks-block-height,
        funded-at: none,
        dispute-deadline: none,
        completion-code: completion-code
      }
    )
    
    ;; Update user escrow lists
    (unwrap! (add-escrow-to-user tx-sender escrow-id) ERR_LIST_FULL)
    (unwrap! (add-escrow-to-user seller escrow-id) ERR_LIST_FULL)
    
    ;; Increment escrow ID
    (var-set next-escrow-id (+ escrow-id u1))
    
    (ok escrow-id)
  )
)

;; Fund escrow (buyer deposits funds)
(define-public (fund-escrow (escrow-id uint))
  (let ((escrow-data (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND)))
    ;; Added escrow-id validation
    (asserts! (validate-escrow-id escrow-id) ERR_INVALID_ESCROW_ID)
    (asserts! (is-eq tx-sender (get buyer escrow-data)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get state escrow-data) STATE_PENDING) ERR_INVALID_STATE)
    
    ;; Transfer funds to contract
    (try! (stx-transfer? (+ (get amount escrow-data) (get fee escrow-data)) tx-sender (as-contract tx-sender)))
    
    ;; Update escrow state
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow-data { 
        state: STATE_FUNDED,
        ;; Updated block-height to stacks-block-height
        funded-at: (some stacks-block-height),
        dispute-deadline: (some (+ stacks-block-height (var-get dispute-period)))
      })
    )
    
    (ok true)
  )
)

;; Complete escrow (seller provides completion code or buyer confirms)
(define-public (complete-escrow (escrow-id uint) (code (optional (string-ascii 32))))
  (let ((escrow-data (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND)))
    ;; Added input validation for escrow-id and completion code
    (asserts! (validate-escrow-id escrow-id) ERR_INVALID_ESCROW_ID)
    (asserts! (validate-completion-code code) ERR_INVALID_STRING)
    (asserts! (is-eq (get state escrow-data) STATE_FUNDED) ERR_INVALID_STATE)
    (asserts! 
      (or 
        (is-eq tx-sender (get buyer escrow-data))
        (and 
          (is-eq tx-sender (get seller escrow-data))
          (is-some (get completion-code escrow-data))
          (is-eq code (get completion-code escrow-data))
        )
      ) 
      ERR_NOT_AUTHORIZED
    )
    
    ;; Transfer funds to seller
    (try! (as-contract (stx-transfer? (get amount escrow-data) tx-sender (get seller escrow-data))))
    
    ;; Transfer fee to contract owner
    (try! (as-contract (stx-transfer? (get fee escrow-data) tx-sender CONTRACT_OWNER)))
    
    ;; Update state
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow-data { state: STATE_COMPLETED })
    )
    
    (ok true)
  )
)

;; Initiate dispute
(define-public (initiate-dispute (escrow-id uint))
  (let ((escrow-data (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND)))
    ;; Added escrow-id validation
    (asserts! (validate-escrow-id escrow-id) ERR_INVALID_ESCROW_ID)
    (asserts! (is-eq (get state escrow-data) STATE_FUNDED) ERR_INVALID_STATE)
    (asserts! 
      (or 
        (is-eq tx-sender (get buyer escrow-data))
        (is-eq tx-sender (get seller escrow-data))
      ) 
      ERR_NOT_AUTHORIZED
    )
    (asserts! 
      ;; Updated block-height to stacks-block-height
      (< stacks-block-height (unwrap! (get dispute-deadline escrow-data) ERR_DISPUTE_PERIOD_EXPIRED))
      ERR_DISPUTE_PERIOD_EXPIRED
    )
    
    ;; Update state
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow-data { state: STATE_DISPUTED })
    )
    
    (ok true)
  )
)

;; Vote on dispute (arbitrator only)
(define-public (vote-dispute (escrow-id uint) (favor-buyer bool))
  (let ((escrow-data (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND)))
    ;; Added escrow-id validation
    (asserts! (validate-escrow-id escrow-id) ERR_INVALID_ESCROW_ID)
    (asserts! (is-eq (get state escrow-data) STATE_DISPUTED) ERR_INVALID_STATE)
    (asserts! 
      (is-eq tx-sender (unwrap! (get arbitrator escrow-data) ERR_NOT_AUTHORIZED))
      ERR_NOT_AUTHORIZED
    )
    
    ;; Record vote
    (map-set dispute-votes
      { escrow-id: escrow-id, voter: tx-sender }
      ;; Updated block-height to stacks-block-height
      { vote: favor-buyer, voted-at: stacks-block-height }
    )
    
    ;; Resolve dispute
    (if favor-buyer
      ;; Refund to buyer
      (try! (as-contract (stx-transfer? (get amount escrow-data) tx-sender (get buyer escrow-data))))
      ;; Pay seller
      (try! (as-contract (stx-transfer? (get amount escrow-data) tx-sender (get seller escrow-data))))
    )
    
    ;; Transfer fee to contract owner
    (try! (as-contract (stx-transfer? (get fee escrow-data) tx-sender CONTRACT_OWNER)))
    
    ;; Update state
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow-data { state: STATE_RESOLVED })
    )
    
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-escrow (escrow-id uint))
  (map-get? escrows { escrow-id: escrow-id })
)

(define-read-only (get-user-escrows (user principal))
  (default-to (list) (get escrow-ids (map-get? user-escrows { user: user })))
)

(define-read-only (get-platform-stats)
  (ok {
    total-escrows: (- (var-get next-escrow-id) u1),
    platform-fee-rate: (var-get platform-fee-rate),
    dispute-period: (var-get dispute-period)
  })
)
