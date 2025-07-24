;; Work Chain - Employment Background Verification Contract
;; Self-Sovereign Identity System on Stacks Blockchain

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_DATES (err u103))
(define-constant ERR_INVALID_EMPLOYER (err u104))

;; Data structures
(define-map user-profiles
  { user: principal }
  {
    created-at: uint,
    verified: bool,
    total-employments: uint
  }
)

(define-map employment-records
  { user: principal, employment-id: uint }
  {
    employer: principal,
    company-name: (string-ascii 100),
    position: (string-ascii 100),
    start-date: uint,
    end-date: (optional uint),
    salary-range: (string-ascii 50),
    verified-by-employer: bool,
    created-at: uint,
    updated-at: uint
  }
)

(define-map employer-verifications
  { employer: principal, user: principal, employment-id: uint }
  {
    verified: bool,
    verification-date: uint,
    notes: (string-ascii 500)
  }
)

(define-map authorized-employers
  { employer: principal }
  {
    company-name: (string-ascii 100),
    registration-date: uint,
    active: bool
  }
)

;; User identity management
(define-public (create-user-profile)
  (let ((user tx-sender))
    (match (map-get? user-profiles { user: user })
      existing-profile ERR_ALREADY_EXISTS
      (ok (map-set user-profiles
        { user: user }
        {
          created-at: block-height,
          verified: false,
          total-employments: u0
        }
      ))
    )
  )
)

(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user })
)

;; Employment record management
(define-public (add-employment-record 
  (employer principal)
  (company-name (string-ascii 100))
  (position (string-ascii 100))
  (start-date uint)
  (end-date (optional uint))
  (salary-range (string-ascii 50)))
  (let (
    (user tx-sender)
    (user-profile (unwrap! (map-get? user-profiles { user: user }) ERR_NOT_FOUND))
    (employment-id (+ (get total-employments user-profile) u1))
  )
    ;; Validate dates
    (asserts! (match end-date
      some-end (>= some-end start-date)
      true
    ) ERR_INVALID_DATES)
    
    ;; Add employment record
    (map-set employment-records
      { user: user, employment-id: employment-id }
      {
        employer: employer,
        company-name: company-name,
        position: position,
        start-date: start-date,
        end-date: end-date,
        salary-range: salary-range,
        verified-by-employer: false,
        created-at: block-height,
        updated-at: block-height
      }
    )
    
    ;; Update user profile
    (map-set user-profiles
      { user: user }
      (merge user-profile { total-employments: employment-id })
    )
    
    (ok employment-id)
  )
)

(define-public (update-employment-record
  (employment-id uint)
  (company-name (string-ascii 100))
  (position (string-ascii 100))
  (start-date uint)
  (end-date (optional uint))
  (salary-range (string-ascii 50)))
  (let (
    (user tx-sender)
    (record-key { user: user, employment-id: employment-id })
    (existing-record (unwrap! (map-get? employment-records record-key) ERR_NOT_FOUND))
  )
    ;; Validate dates
    (asserts! (match end-date
      some-end (>= some-end start-date)
      true
    ) ERR_INVALID_DATES)
    
    ;; Update record
    (ok (map-set employment-records
      record-key
      (merge existing-record {
        company-name: company-name,
        position: position,
        start-date: start-date,
        end-date: end-date,
        salary-range: salary-range,
        updated-at: block-height
      })
    ))
  )
)

(define-read-only (get-employment-record (user principal) (employment-id uint))
  (map-get? employment-records { user: user, employment-id: employment-id })
)

;; Employer verification system
(define-public (register-as-employer (company-name (string-ascii 100)))
  (let ((employer tx-sender))
    (match (map-get? authorized-employers { employer: employer })
      existing-employer ERR_ALREADY_EXISTS
      (ok (map-set authorized-employers
        { employer: employer }
        {
          company-name: company-name,
          registration-date: block-height,
          active: true
        }
      ))
    )
  )
)

(define-public (verify-employment
  (user principal)
  (employment-id uint)
  (notes (string-ascii 500)))
  (let (
    (employer tx-sender)
    (record-key { user: user, employment-id: employment-id })
    (employment-record (unwrap! (map-get? employment-records record-key) ERR_NOT_FOUND))
    (employer-info (unwrap! (map-get? authorized-employers { employer: employer }) ERR_UNAUTHORIZED))
  )
    ;; Check if employer is authorized and active
    (asserts! (get active employer-info) ERR_UNAUTHORIZED)
    
    ;; Check if employer matches the employment record
    (asserts! (is-eq employer (get employer employment-record)) ERR_INVALID_EMPLOYER)
    
    ;; Update employment record verification status
    (map-set employment-records
      record-key
      (merge employment-record {
        verified-by-employer: true,
        updated-at: block-height
      })
    )
    
    ;; Add verification record
    (map-set employer-verifications
      { employer: employer, user: user, employment-id: employment-id }
      {
        verified: true,
        verification-date: block-height,
        notes: notes
      }
    )
    
    (ok true)
  )
)

(define-public (revoke-verification
  (user principal)
  (employment-id uint)
  (notes (string-ascii 500)))
  (let (
    (employer tx-sender)
    (record-key { user: user, employment-id: employment-id })
    (employment-record (unwrap! (map-get? employment-records record-key) ERR_NOT_FOUND))
    (verification-key { employer: employer, user: user, employment-id: employment-id })
  )
    ;; Check if verification exists
    (unwrap! (map-get? employer-verifications verification-key) ERR_NOT_FOUND)
    
    ;; Update employment record
    (map-set employment-records
      record-key
      (merge employment-record {
        verified-by-employer: false,
        updated-at: block-height
      })
    )
    
    ;; Update verification record
    (map-set employer-verifications
      verification-key
      {
        verified: false,
        verification-date: block-height,
        notes: notes
      }
    )
    
    (ok true)
  )
)

;; Query functions
(define-read-only (get-verification-status 
  (employer principal) 
  (user principal) 
  (employment-id uint))
  (map-get? employer-verifications { employer: employer, user: user, employment-id: employment-id })
)

(define-read-only (get-employer-info (employer principal))
  (map-get? authorized-employers { employer: employer })
)

(define-read-only (is-verified-employment (user principal) (employment-id uint))
  (match (map-get? employment-records { user: user, employment-id: employment-id })
    some-record (get verified-by-employer some-record)
    false
  )
)

;; Get all employment records for a user (simplified version)
(define-read-only (get-user-employment-count (user principal))
  (match (map-get? user-profiles { user: user })
    some-profile (get total-employments some-profile)
    u0
  )
)

;; Utility functions
(define-read-only (get-contract-info)
  {
    name: "Work History Verification",
    version: "1.0.0",
    description: "Self-sovereign identity system for employment background verification"
  }
)

;; Admin functions (for contract owner only)
(define-public (deactivate-employer (employer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? authorized-employers { employer: employer })
      some-employer (ok (map-set authorized-employers
        { employer: employer }
        (merge some-employer { active: false })
      ))
      ERR_NOT_FOUND
    )
  )
)

(define-public (reactivate-employer (employer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? authorized-employers { employer: employer })
      some-employer (ok (map-set authorized-employers
        { employer: employer }
        (merge some-employer { active: true })
      ))
      ERR_NOT_FOUND
    )
  )
)