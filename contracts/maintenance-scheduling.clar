;; Maintenance Scheduling Contract
;; Manages fleet upkeep and maintenance schedules

(define-map maintenance-schedules
  { vehicle-id: uint }
  {
    last-maintenance: uint,
    next-maintenance: uint,
    maintenance-interval: uint,
    maintenance-type: (string-ascii 30),
    maintenance-required: bool
  }
)

(define-map maintenance-records
  { vehicle-id: uint, maintenance-id: uint }
  {
    timestamp: uint,
    maintenance-type: (string-ascii 30),
    cost: uint,
    duration: uint,
    technician: principal,
    completed: bool
  }
)

(define-data-var next-maintenance-id uint u1)

;; Initialize maintenance schedule
(define-public (init-maintenance-schedule (vehicle-id uint) (maintenance-interval uint))
  (begin
    (map-set maintenance-schedules
      { vehicle-id: vehicle-id }
      {
        last-maintenance: block-height,
        next-maintenance: (+ block-height maintenance-interval),
        maintenance-interval: maintenance-interval,
        maintenance-type: "routine",
        maintenance-required: false
      }
    )
    (ok true)
  )
)

;; Schedule maintenance
(define-public (schedule-maintenance (vehicle-id uint) (maintenance-type (string-ascii 30)) (cost uint) (duration uint))
  (let ((maintenance-id (var-get next-maintenance-id)))
    (map-set maintenance-records
      { vehicle-id: vehicle-id, maintenance-id: maintenance-id }
      {
        timestamp: block-height,
        maintenance-type: maintenance-type,
        cost: cost,
        duration: duration,
        technician: tx-sender,
        completed: false
      }
    )
    (match (map-get? maintenance-schedules { vehicle-id: vehicle-id })
      schedule
      (map-set maintenance-schedules
        { vehicle-id: vehicle-id }
        (merge schedule { maintenance-required: true })
      )
      false
    )
    (var-set next-maintenance-id (+ maintenance-id u1))
    (ok maintenance-id)
  )
)

;; Complete maintenance
(define-public (complete-maintenance (vehicle-id uint) (maintenance-id uint))
  (match (map-get? maintenance-records { vehicle-id: vehicle-id, maintenance-id: maintenance-id })
    record-data
    (begin
      (map-set maintenance-records
        { vehicle-id: vehicle-id, maintenance-id: maintenance-id }
        (merge record-data { completed: true })
      )
      (match (map-get? maintenance-schedules { vehicle-id: vehicle-id })
        schedule
        (map-set maintenance-schedules
          { vehicle-id: vehicle-id }
          (merge schedule {
            last-maintenance: block-height,
            next-maintenance: (+ block-height (get maintenance-interval schedule)),
            maintenance-required: false
          })
        )
        false
      )
      (ok true)
    )
    (err u404)
  )
)

;; Check if maintenance is due
(define-read-only (is-maintenance-due (vehicle-id uint))
  (match (map-get? maintenance-schedules { vehicle-id: vehicle-id })
    schedule
    (or (get maintenance-required schedule)
        (>= block-height (get next-maintenance schedule)))
    false
  )
)

;; Get maintenance schedule
(define-read-only (get-maintenance-schedule (vehicle-id uint))
  (map-get? maintenance-schedules { vehicle-id: vehicle-id })
)

;; Get maintenance record
(define-read-only (get-maintenance-record (vehicle-id uint) (maintenance-id uint))
  (map-get? maintenance-records { vehicle-id: vehicle-id, maintenance-id: maintenance-id })
)
