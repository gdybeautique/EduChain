;; EduChain - Decentralized Education Credential Verification System
;; Supporting SDG Goal 4: Quality Education
;; Ensures transparent and tamper-proof educational credential verification

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSTITUTION_NOT_FOUND (err u101))
(define-constant ERR_CREDENTIAL_NOT_FOUND (err u102))
(define-constant ERR_INSTITUTION_EXISTS (err u103))
(define-constant ERR_CREDENTIAL_EXISTS (err u104))
(define-constant ERR_INVALID_INPUT (err u105))

;; Data structures
(define-map institutions
  { institution-id: uint }
  {
    name: (string-ascii 100),
    accreditation-body: (string-ascii 100),
    authorized-issuer: principal,
    is-active: bool,
    registration-block: uint
  }
)

(define-map credentials
  { credential-id: uint }
  {
    student-address: principal,
    institution-id: uint,
    degree-type: (string-ascii 50),
    field-of-study: (string-ascii 100),
    graduation-date: uint,
    gpa: uint, ;; GPA * 100 (e.g., 3.75 = 375)
    ipfs-hash: (string-ascii 64), ;; IPFS hash for certificate document
    issue-block: uint,
    is-verified: bool
  }
)

(define-map student-credentials
  { student: principal }
  { credential-ids: (list 20 uint) }
)

;; Data variables
(define-data-var next-institution-id uint u1)
(define-data-var next-credential-id uint u1)
(define-data-var total-institutions uint u0)
(define-data-var total-credentials uint u0)

;; Read-only functions
(define-read-only (get-institution (institution-id uint))
  (map-get? institutions { institution-id: institution-id })
)

(define-read-only (get-credential (credential-id uint))
  (map-get? credentials { credential-id: credential-id })
)

(define-read-only (get-student-credentials (student principal))
  (default-to 
    { credential-ids: (list) }
    (map-get? student-credentials { student: student })
  )
)

(define-read-only (verify-credential (credential-id uint))
  (match (get-credential credential-id)
    credential (ok {
      is-valid: (get is-verified credential),
      student: (get student-address credential),
      institution-id: (get institution-id credential),
      degree: (get degree-type credential),
      field: (get field-of-study credential),
      graduation-date: (get graduation-date credential)
    })
    ERR_CREDENTIAL_NOT_FOUND
  )
)

(define-read-only (get-contract-stats)
  (ok {
    total-institutions: (var-get total-institutions),
    total-credentials: (var-get total-credentials),
    next-institution-id: (var-get next-institution-id),
    next-credential-id: (var-get next-credential-id)
  })
)

;; Private functions
(define-private (is-valid-string (str (string-ascii 100)))
  (> (len str) u0)
)

;; Public functions

;; Register a new educational institution
(define-public (register-institution 
  (name (string-ascii 100))
  (accreditation-body (string-ascii 100))
  (authorized-issuer principal)
)
  (let ((institution-id (var-get next-institution-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-valid-string name) ERR_INVALID_INPUT)
    (asserts! (is-valid-string accreditation-body) ERR_INVALID_INPUT)
    
    (map-set institutions
      { institution-id: institution-id }
      {
        name: name,
        accreditation-body: accreditation-body,
        authorized-issuer: authorized-issuer,
        is-active: true,
        registration-block: block-height
      }
    )
    
    (var-set next-institution-id (+ institution-id u1))
    (var-set total-institutions (+ (var-get total-institutions) u1))
    
    (ok institution-id)
  )
)

;; Issue a new credential
(define-public (issue-credential
  (student-address principal)
  (institution-id uint)
  (degree-type (string-ascii 50))
  (field-of-study (string-ascii 100))
  (graduation-date uint)
  (gpa uint)
  (ipfs-hash (string-ascii 64))
)
  (let (
    (credential-id (var-get next-credential-id))
    (institution (unwrap! (get-institution institution-id) ERR_INSTITUTION_NOT_FOUND))
    (current-credentials (get credential-ids (get-student-credentials student-address)))
  )
    ;; Verify issuer is authorized for this institution
    (asserts! (is-eq tx-sender (get authorized-issuer institution)) ERR_UNAUTHORIZED)
    (asserts! (get is-active institution) ERR_UNAUTHORIZED)
    (asserts! (is-valid-string degree-type) ERR_INVALID_INPUT)
    (asserts! (is-valid-string field-of-study) ERR_INVALID_INPUT)
    (asserts! (<= gpa u400) ERR_INVALID_INPUT) ;; Max GPA of 4.00
    (asserts! (> (len ipfs-hash) u0) ERR_INVALID_INPUT)
    
    ;; Create credential
    (map-set credentials
      { credential-id: credential-id }
      {
        student-address: student-address,
        institution-id: institution-id,
        degree-type: degree-type,
        field-of-study: field-of-study,
        graduation-date: graduation-date,
        gpa: gpa,
        ipfs-hash: ipfs-hash,
        issue-block: block-height,
        is-verified: true
      }
    )
    
    ;; Update student's credential list
    (map-set student-credentials
      { student: student-address }
      { credential-ids: (unwrap! (as-max-len? (append current-credentials credential-id) u20) ERR_INVALID_INPUT) }
    )
    
    (var-set next-credential-id (+ credential-id u1))
    (var-set total-credentials (+ (var-get total-credentials) u1))
    
    (ok credential-id)
  )
)

;; Revoke a credential (in case of fraud or error)
(define-public (revoke-credential (credential-id uint))
  (let ((credential (unwrap! (get-credential credential-id) ERR_CREDENTIAL_NOT_FOUND)))
    (let ((institution (unwrap! (get-institution (get institution-id credential)) ERR_INSTITUTION_NOT_FOUND)))
      (asserts! (is-eq tx-sender (get authorized-issuer institution)) ERR_UNAUTHORIZED)
      
      (map-set credentials
        { credential-id: credential-id }
        (merge credential { is-verified: false })
      )
      
      (ok true)
    )
  )
)

;; Deactivate an institution
(define-public (deactivate-institution (institution-id uint))
  (let ((institution (unwrap! (get-institution institution-id) ERR_INSTITUTION_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    (map-set institutions
      { institution-id: institution-id }
      (merge institution { is-active: false })
    )
    
    (ok true)
  )
)

;; Update institution authorized issuer
(define-public (update-institution-issuer 
  (institution-id uint) 
  (new-issuer principal)
)
  (let ((institution (unwrap! (get-institution institution-id) ERR_INSTITUTION_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    (map-set institutions
      { institution-id: institution-id }
      (merge institution { authorized-issuer: new-issuer })
    )
    
    (ok true)
  )
)