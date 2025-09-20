
;; title: IndustryStandards
;; version: 1.0.0
;; summary: A professional voting platform for technical specifications and best practice adoption
;; description: This contract manages proposals for technical standards, enables stakeholder voting,
;;              and tracks reputation based on participation in the governance process.

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-VOTED (err u102))
(define-constant ERR-VOTING-ENDED (err u103))
(define-constant ERR-VOTING-NOT-ENDED (err u104))
(define-constant ERR-INVALID-VOTE (err u105))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u106))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-REPUTATION-TO-PROPOSE u100)
(define-constant VOTING-PERIOD u2016) ;; ~2 weeks in blocks (assuming 10min blocks)
(define-constant REPUTATION-PER-VOTE u10)
(define-constant REPUTATION-PER-PROPOSAL u50)

;; Data variables
(define-data-var proposal-counter uint u0)
(define-data-var contract-active bool true)

;; Data maps
;; Proposals storage
(define-map proposals
  { proposal-id: uint }
  {
    title: (string-utf8 100),
    description: (string-utf8 500),
    proposer: principal,
    start-block: uint,
    end-block: uint,
    votes-for: uint,
    votes-against: uint,
    status: (string-ascii 10) ;; "active", "passed", "rejected"
  }
)

;; Track who voted on which proposal
(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, block-height: uint }
)

;; User reputation tracking
(define-map user-reputation
  { user: principal }
  { reputation: uint, proposals-created: uint, votes-cast: uint }
)

;; Authorized proposers (can be expanded to a more complex system)
(define-map authorized-proposers
  { user: principal }
  { authorized: bool }
)

;; Public functions

;; Initialize user reputation (first-time users)
(define-public (initialize-user)
  (let ((user tx-sender))
    (match (map-get? user-reputation { user: user })
      existing-rep (ok false)
      (begin
        (map-set user-reputation
          { user: user }
          { reputation: u0, proposals-created: u0, votes-cast: u0 }
        )
        (ok true)
      )
    )
  )
)

;; Create a new proposal
(define-public (create-proposal (title (string-utf8 100)) (description (string-utf8 500)))
  (let (
    (proposer tx-sender)
    (current-counter (var-get proposal-counter))
    (new-proposal-id (+ current-counter u1))
    (start-block block-height)
    (end-block (+ block-height VOTING-PERIOD))
    (user-rep (default-to { reputation: u0, proposals-created: u0, votes-cast: u0 }
                (map-get? user-reputation { user: proposer })))
  )
    ;; Check if contract is active
    (asserts! (var-get contract-active) ERR-NOT-AUTHORIZED)

    ;; Check if user has sufficient reputation or is authorized
    (asserts! (or
      (>= (get reputation user-rep) MIN-REPUTATION-TO-PROPOSE)
      (default-to false (get authorized (map-get? authorized-proposers { user: proposer })))
      (is-eq proposer CONTRACT-OWNER)
    ) ERR-INSUFFICIENT-REPUTATION)

    ;; Create the proposal
    (map-set proposals
      { proposal-id: new-proposal-id }
      {
        title: title,
        description: description,
        proposer: proposer,
        start-block: start-block,
        end-block: end-block,
        votes-for: u0,
        votes-against: u0,
        status: "active"
      }
    )

    ;; Update proposal counter
    (var-set proposal-counter new-proposal-id)

    ;; Update proposer's reputation
    (map-set user-reputation
      { user: proposer }
      {
        reputation: (+ (get reputation user-rep) REPUTATION-PER-PROPOSAL),
        proposals-created: (+ (get proposals-created user-rep) u1),
        votes-cast: (get votes-cast user-rep)
      }
    )

    (ok new-proposal-id)
  )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (let (
    (voter tx-sender)
    (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
    (existing-vote (map-get? votes { proposal-id: proposal-id, voter: voter }))
    (user-rep (default-to { reputation: u0, proposals-created: u0, votes-cast: u0 }
                (map-get? user-reputation { user: voter })))
  )
    ;; Check if proposal exists and is active
    (asserts! (is-eq (get status proposal) "active") ERR-VOTING-ENDED)

    ;; Check if voting period is still active
    (asserts! (<= block-height (get end-block proposal)) ERR-VOTING-ENDED)

    ;; Check if user hasn't voted yet
    (asserts! (is-none existing-vote) ERR-ALREADY-VOTED)

    ;; Record the vote
    (map-set votes
      { proposal-id: proposal-id, voter: voter }
      { vote: vote-for, block-height: block-height }
    )

    ;; Update proposal vote counts
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal {
        votes-for: (if vote-for (+ (get votes-for proposal) u1) (get votes-for proposal)),
        votes-against: (if vote-for (get votes-against proposal) (+ (get votes-against proposal) u1))
      })
    )

    ;; Update voter's reputation
    (map-set user-reputation
      { user: voter }
      {
        reputation: (+ (get reputation user-rep) REPUTATION-PER-VOTE),
        proposals-created: (get proposals-created user-rep),
        votes-cast: (+ (get votes-cast user-rep) u1)
      }
    )

    (ok true)
  )
)

;; Finalize a proposal (can be called by anyone after voting period ends)
(define-public (finalize-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
  )
    ;; Check if voting period has ended
    (asserts! (> block-height (get end-block proposal)) ERR-VOTING-NOT-ENDED)

    ;; Check if proposal is still active
    (asserts! (is-eq (get status proposal) "active") ERR-VOTING-ENDED)

    ;; Determine outcome and update status
    (let (
      (votes-for (get votes-for proposal))
      (votes-against (get votes-against proposal))
      (new-status (if (> votes-for votes-against) "passed" "rejected"))
    )
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { status: new-status })
      )
      (ok new-status)
    )
  )
)

;; Authorize a user to create proposals (only contract owner)
(define-public (authorize-proposer (user principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set authorized-proposers
      { user: user }
      { authorized: true }
    )
    (ok true)
  )
)

;; Revoke authorization (only contract owner)
(define-public (revoke-proposer (user principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set authorized-proposers
      { user: user }
      { authorized: false }
    )
    (ok true)
  )
)

;; Emergency pause/unpause (only contract owner)
(define-public (toggle-contract-active)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)

;; Read-only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

;; Get user's vote on a specific proposal
(define-read-only (get-user-vote (proposal-id uint) (user principal))
  (map-get? votes { proposal-id: proposal-id, voter: user })
)

;; Get user reputation
(define-read-only (get-user-reputation (user principal))
  (map-get? user-reputation { user: user })
)

;; Check if user is authorized to propose
(define-read-only (is-authorized-proposer (user principal))
  (default-to false (get authorized (map-get? authorized-proposers { user: user })))
)

;; Get current proposal counter
(define-read-only (get-proposal-counter)
  (var-get proposal-counter)
)

;; Check if contract is active
(define-read-only (is-contract-active)
  (var-get contract-active)
)

;; Get proposal status and vote summary
(define-read-only (get-proposal-summary (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal (some {
      title: (get title proposal),
      status: (get status proposal),
      votes-for: (get votes-for proposal),
      votes-against: (get votes-against proposal),
      total-votes: (+ (get votes-for proposal) (get votes-against proposal)),
      end-block: (get end-block proposal),
      blocks-remaining: (if (> (get end-block proposal) block-height)
                          (- (get end-block proposal) block-height)
                          u0)
    })
    none
  )
)

;; Private functions

;; Helper function to check if voting is active for a proposal
(define-private (is-voting-active (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal (and
      (is-eq (get status proposal) "active")
      (<= block-height (get end-block proposal))
    )
    false
  )
)
