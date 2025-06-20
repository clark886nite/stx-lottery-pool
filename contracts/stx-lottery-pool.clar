;; ------------------------------------------------------------
;; Contract: stx-lottery-pool
;; Purpose: A decentralized lottery game on Stacks blockchain
;; Author: [Your Name]
;; License: MIT
;; ------------------------------------------------------------

(define-constant ERR_ALREADY_ENTERED (err u100))
(define-constant ERR_LOTTERY_NOT_ACTIVE (err u101))
(define-constant ERR_NOT_ENDED (err u102))
(define-constant ERR_NO_PARTICIPANTS (err u103))
(define-constant ERR_NOT_ADMIN (err u104))
(define-constant ERR_TRANSFER_FAILED (err u105))
(define-constant ERR_ALREADY_PARTICIPATED (err u106))
(define-constant ERR_LIST_FULL (err u107))
(define-constant ENTRY_FEE u1000000) ;; 1 STX

(define-data-var admin principal tx-sender)
(define-data-var is-active bool true)
(define-data-var lottery-end uint (+ stacks-block-height u100)) ;; ends in 100 blocks
(define-data-var participants (list 100 principal) (list))

;; Track if a user has already entered
(define-map has-entered principal bool)

;; === Helper function to check if user already entered ===
(define-private (user-already-entered (user principal))
  (default-to false (map-get? has-entered user))
)

;; === Enter the lottery by sending 1 STX ===
(define-public (enter-lottery)
  (begin
    (asserts! (var-get is-active) ERR_LOTTERY_NOT_ACTIVE)
    (asserts! (< stacks-block-height (var-get lottery-end)) ERR_NOT_ENDED)
    (asserts! (not (user-already-entered tx-sender)) ERR_ALREADY_PARTICIPATED)
    
    ;; Transfer entry fee to contract
    (unwrap! (stx-transfer? ENTRY_FEE tx-sender (as-contract tx-sender)) ERR_TRANSFER_FAILED)
    
    ;; Add participant to list
    (var-set participants 
      (unwrap! (as-max-len? (append (var-get participants) tx-sender) u100) ERR_LIST_FULL))
    
    ;; Mark user as entered
    (map-set has-entered tx-sender true)
    (ok true)
  )
)

;; === Draw a winner (only admin, after lottery ends) ===
(define-public (draw-winner)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_ADMIN)
    (asserts! (var-get is-active) ERR_LOTTERY_NOT_ACTIVE)
    (asserts! (>= stacks-block-height (var-get lottery-end)) ERR_NOT_ENDED)

    (let (
      (players (var-get participants))
      (count (len players))
    )
      (asserts! (> count u0) ERR_NO_PARTICIPANTS)

      ;; Pick winner using block height and hash for randomness
      (let (
        (random-seed (+ stacks-block-height (len players)))
        (hash-input (unwrap-panic (to-consensus-buff? random-seed)))
        (hash-result (sha256 hash-input))
        (random-byte (unwrap-panic (element-at hash-result u0)))
        (index (mod (convert-byte-to-uint random-byte) count))
        (winner (unwrap! (element-at players index) ERR_NO_PARTICIPANTS))
      )
        ;; Calculate and transfer prize
        (let ((prize (* ENTRY_FEE count)))
          (unwrap! (as-contract (stx-transfer? prize tx-sender winner)) ERR_TRANSFER_FAILED)
          (var-set is-active false)
          (ok winner)
        )
      )
    )
  )
)

;; === Start a new lottery round (only admin) ===
(define-public (start-new-round (duration uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_ADMIN)
    (asserts! (not (var-get is-active)) ERR_LOTTERY_NOT_ACTIVE)
    
    ;; Clear previous round data
    (var-set participants (list))
    (var-set is-active true)
    (var-set lottery-end (+ stacks-block-height duration))
    
    ;; Clear the has-entered map for new round
    ;; Note: In a real implementation, you might want to track this differently
    ;; since we can't easily clear all entries from a map
    (ok true)
  )
)

;; === Admin function to change admin ===
(define-public (change-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_ADMIN)
    (var-set admin new-admin)
    (ok true)
  )
)

;; === Emergency function to end lottery early (admin only) ===
(define-public (emergency-end)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_ADMIN)
    (var-set is-active false)
    (ok true)
  )
)

;; === Read-only: View participants ===
(define-read-only (get-participants)
  (var-get participants)
)

;; === Read-only: Check if active ===
(define-read-only (is-lottery-active)
  (var-get is-active)
)

;; === Read-only: Get lottery end block ===
(define-read-only (get-lottery-end)
  (var-get lottery-end)
)

;; === Read-only: Get current prize pool ===
(define-read-only (get-prize-pool)
  (* ENTRY_FEE (len (var-get participants)))
)

;; === Read-only: Get participant count ===
(define-read-only (get-participant-count)
  (len (var-get participants))
)

;; === Read-only: Check if user has entered ===
(define-read-only (has-user-entered (user principal))
  (user-already-entered user)
)

;; === Read-only: Get admin ===
(define-read-only (get-admin)
  (var-get admin)
)

;; === Read-only: Get blocks remaining ===
(define-read-only (blocks-remaining)
  (if (>= stacks-block-height (var-get lottery-end))
    u0
    (- (var-get lottery-end) stacks-block-height)
  )
)

;; Helper function to convert single byte to uint
(define-private (convert-byte-to-uint (byte (buff 1)))
  (buff-to-uint-le byte)
)