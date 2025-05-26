;; Route Optimization Contract
;; Plans and manages efficient autonomous routes

(define-map routes
  { route-id: uint }
  {
    start-zone: uint,
    end-zone: uint,
    distance: uint,
    estimated-time: uint,
    traffic-level: uint,
    priority: uint,
    active: bool
  }
)

(define-map route-assignments
  { vehicle-id: uint }
  {
    route-id: uint,
    start-time: uint,
    estimated-completion: uint,
    actual-completion: (optional uint)
  }
)

(define-data-var next-route-id uint u1)

;; Create a new route
(define-public (create-route (start-zone uint) (end-zone uint) (distance uint) (estimated-time uint))
  (let ((route-id (var-get next-route-id)))
    (map-set routes
      { route-id: route-id }
      {
        start-zone: start-zone,
        end-zone: end-zone,
        distance: distance,
        estimated-time: estimated-time,
        traffic-level: u1,
        priority: u1,
        active: true
      }
    )
    (var-set next-route-id (+ route-id u1))
    (ok route-id)
  )
)

;; Assign route to vehicle
(define-public (assign-route (vehicle-id uint) (route-id uint))
  (match (map-get? routes { route-id: route-id })
    route-data
    (if (get active route-data)
      (begin
        (map-set route-assignments
          { vehicle-id: vehicle-id }
          {
            route-id: route-id,
            start-time: block-height,
            estimated-completion: (+ block-height (get estimated-time route-data)),
            actual-completion: none
          }
        )
        (ok true)
      )
      (err u400)
    )
    (err u404)
  )
)

;; Complete route
(define-public (complete-route (vehicle-id uint))
  (match (map-get? route-assignments { vehicle-id: vehicle-id })
    assignment-data
    (begin
      (map-set route-assignments
        { vehicle-id: vehicle-id }
        (merge assignment-data { actual-completion: (some block-height) })
      )
      (ok true)
    )
    (err u404)
  )
)

;; Update traffic level
(define-public (update-traffic (route-id uint) (traffic-level uint))
  (match (map-get? routes { route-id: route-id })
    route-data
    (begin
      (map-set routes
        { route-id: route-id }
        (merge route-data { traffic-level: traffic-level })
      )
      (ok true)
    )
    (err u404)
  )
)

;; Get route info
(define-read-only (get-route (route-id uint))
  (map-get? routes { route-id: route-id })
)

;; Get vehicle assignment
(define-read-only (get-assignment (vehicle-id uint))
  (map-get? route-assignments { vehicle-id: vehicle-id })
)
